package api

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/expotoworld/expotoworld/backend/ebook-service/internal/mediatools"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

func adminEnabled() bool {
	// Option B: always enabled for authenticated authors
	return true
}

// AdminReindexHandler seeds ebook_media_usage and ebook_version_media from current sources.
func AdminReindexHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !adminEnabled() {
			c.JSON(http.StatusForbidden, gin.H{"error": "admin tools disabled"})
			return
		}
		ctx, cancel := context.WithTimeout(c.Request.Context(), 60*time.Second)
		defer cancel()

		// Reset usage counts (keep keys but zero them)
		if _, err := db.Exec(ctx, `UPDATE ebook_media_usage SET in_autosave=false, manual_refs=0, published_refs=0`); err != nil {
			log.Printf("reindex: reset usage failed: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "reset failed"})
			return
		}

		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		allowedPrefix := "ebooks/huashangdao/"

		// Autosave content
		var contentRaw []byte
		if err := db.QueryRow(ctx, `SELECT COALESCE(content,'{}'::jsonb)::text FROM ebooks WHERE slug='main'`).Scan(&contentRaw); err == nil {
			var content any
			_ = json.Unmarshal(contentRaw, &content)
			keys := mediatools.ExtractMediaKeys(content, cdnBase, allowedPrefix)
			for _, k := range keys {
				_, _ = db.Exec(ctx, `INSERT INTO ebook_media_usage(media_key,in_autosave,last_seen_at) VALUES ($1,true,now()) ON CONFLICT (media_key) DO UPDATE SET in_autosave=true,last_seen_at=now()`, k)
			}
		}

		// From version rows: load JSON from S3 and increment counters + mapping
		rows, err := db.Query(ctx, `SELECT id, kind, s3_key FROM ebook_versions`)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer rows.Close()
		region := os.Getenv("AWS_REGION")
		if region == "" {
			region = os.Getenv("AWS_DEFAULT_REGION")
		}
		if region == "" {
			region = "eu-central-1"
		}
		cfg, _ := config.LoadDefaultConfig(ctx, config.WithRegion(region))
		s3c := s3.NewFromConfig(cfg)
		bucket := os.Getenv("EBOOK_S3_BUCKET")
		if bucket == "" {
			bucket = "expotoworld-ebook-versions"
		}
		for rows.Next() {
			var id, kind, key string
			if err := rows.Scan(&id, &kind, &key); err != nil {
				continue
			}
			obj, err := s3c.GetObject(ctx, &s3.GetObjectInput{Bucket: &bucket, Key: &key})
			if err != nil {
				continue
			}
			b, _ := io.ReadAll(obj.Body)
			_ = obj.Body.Close()
			var content any
			_ = json.Unmarshal(b, &content)
			keys := mediatools.ExtractMediaKeys(content, cdnBase, allowedPrefix)
			for _, mk := range keys {
				if kind == "manual" {
					_, _ = db.Exec(ctx, `INSERT INTO ebook_media_usage(media_key,manual_refs,last_seen_at) VALUES ($1,1,now()) ON CONFLICT (media_key) DO UPDATE SET manual_refs=ebook_media_usage.manual_refs+1,last_seen_at=now()`, mk)
				} else {
					_, _ = db.Exec(ctx, `INSERT INTO ebook_media_usage(media_key,published_refs,last_seen_at) VALUES ($1,1,now()) ON CONFLICT (media_key) DO UPDATE SET published_refs=ebook_media_usage.published_refs+1,last_seen_at=now()`, mk)
				}
				_, _ = db.Exec(ctx, `INSERT INTO ebook_version_media(version_id,media_key) VALUES ($1,$2) ON CONFLICT DO NOTHING`, id, mk)
			}
		}
		c.JSON(http.StatusOK, gin.H{"status": "reindexed"})
	}
}

// AdminListPendingHandler lists pending deletions
func AdminListPendingHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !adminEnabled() {
			c.JSON(http.StatusForbidden, gin.H{"error": "admin tools disabled"})
			return
		}
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
		if limit <= 0 || limit > 200 {
			limit = 20
		}
		offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
		rows, err := db.Query(c, `SELECT media_key, requested_at, not_before, attempts, last_checked_at FROM ebook_media_pending_deletion ORDER BY not_before ASC LIMIT $1 OFFSET $2`, limit, offset)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer rows.Close()
		items := []gin.H{}
		for rows.Next() {
			var mediaKey string
			var requestedAt, notBefore time.Time
			var attempts int
			var lastChecked *time.Time
			_ = rows.Scan(&mediaKey, &requestedAt, &notBefore, &attempts, &lastChecked)
			items = append(items, gin.H{"media_key": mediaKey, "requested_at": requestedAt, "not_before": notBefore, "attempts": attempts, "last_checked_at": lastChecked})
		}
		c.JSON(http.StatusOK, gin.H{"items": items, "limit": limit, "offset": offset})
	}
}
