package api

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/expotoworld/expotoworld/backend/ebook-service/internal/mediatools"
	"github.com/expotoworld/expotoworld/backend/ebook-service/internal/storage"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Handlers struct{ DB *pgxpool.Pool }

type versionItem struct {
	ID        string    `json:"id"`
	Kind      string    `json:"kind"`
	S3Key     string    `json:"s3_key"`
	Label     *string   `json:"label,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

func GetEbookVersionsHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		kind := strings.TrimSpace(c.Query("kind"))
		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")
		limit, _ := strconv.Atoi(limitStr)
		if limit <= 0 || limit > 100 {
			limit = 10
		}
		offset, _ := strconv.Atoi(offsetStr)
		if offset < 0 {
			offset = 0
		}

		ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
		defer cancel()

		rows, err := db.Query(ctx,
			`SELECT ev.id, ev.kind, ev.s3_key, ev.label, ev.created_at
			 FROM ebook_versions ev
			 JOIN ebooks e ON e.id = ev.ebook_id
			 WHERE e.slug='main' AND ($1='' OR ev.kind=$1)
			 ORDER BY ev.created_at DESC
			 LIMIT $2 OFFSET $3`, kind, limit, offset,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer rows.Close()

		items := make([]versionItem, 0, limit)
		for rows.Next() {
			var v versionItem
			if err := rows.Scan(&v.ID, &v.Kind, &v.S3Key, &v.Label, &v.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			items = append(items, v)
		}
		c.JSON(http.StatusOK, gin.H{"items": items, "kind": kind, "limit": limit, "offset": offset})
	}
}

func GetDraftEbookHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
		defer cancel()
		var contentRaw []byte
		err := db.QueryRow(ctx, `SELECT COALESCE(content, '{}'::jsonb) FROM ebooks WHERE slug='main'`).Scan(&contentRaw)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var content any
		_ = json.Unmarshal(contentRaw, &content)
		c.JSON(http.StatusOK, gin.H{"content": content})
	}
}

func PutAutosaveEbookHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var newContent any
		if err := c.BindJSON(&newContent); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid JSON"})
			return
		}

		ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
		defer cancel()

		tx, err := db.Begin(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer tx.Rollback(ctx)

		var ebookID string
		var oldContent sql.NullString
		if err := tx.QueryRow(ctx, `SELECT id, content::text FROM ebooks WHERE slug='main' FOR UPDATE`).Scan(&ebookID, &oldContent); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		allowedPrefix := "ebooks/huashangdao/"

		// Compute old/new media sets
		oldKeys := map[string]struct{}{}
		if oldContent.Valid && strings.TrimSpace(oldContent.String) != "" {
			var oc any
			_ = json.Unmarshal([]byte(oldContent.String), &oc)
			for _, k := range mediatools.ExtractMediaKeys(oc, cdnBase, allowedPrefix) {
				oldKeys[k] = struct{}{}
			}
		}
		newKeys := map[string]struct{}{}
		for _, k := range mediatools.ExtractMediaKeys(newContent, cdnBase, allowedPrefix) {
			newKeys[k] = struct{}{}
		}

		// Update ebooks.content
		b, _ := json.Marshal(newContent)
		if _, err := tx.Exec(ctx, `UPDATE ebooks SET content=$1::jsonb, updated_at=now() WHERE id=$2`, string(b), ebookID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		// Maintain usage flags within same transaction
		for k := range newKeys {
			if _, existed := oldKeys[k]; !existed {
				_, _ = tx.Exec(ctx, `INSERT INTO ebook_media_usage(media_key,in_autosave,last_seen_at) VALUES ($1,true,now()) ON CONFLICT (media_key) DO UPDATE SET in_autosave=true,last_seen_at=now()`, k)
			} else {
				_, _ = tx.Exec(ctx, `UPDATE ebook_media_usage SET last_seen_at=now() WHERE media_key=$1`, k)
			}
		}
		for k := range oldKeys {
			if _, still := newKeys[k]; !still {
				_, _ = tx.Exec(ctx, `UPDATE ebook_media_usage SET in_autosave=false WHERE media_key=$1`, k)
			}
		}

		if err := tx.Commit(ctx); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "saved"})
	}
}

type manualReq struct {
	Label string `json:"label"`
}

func PostManualVersionHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req manualReq
		_ = c.ShouldBindJSON(&req)

		ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
		defer cancel()

		uploader, _ := storage.NewS3Uploader(ctx)
		if !uploader.Enabled() {
			c.JSON(http.StatusFailedDependency, gin.H{"error": "s3 not configured"})
			return
		}

		tx, err := db.Begin(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer tx.Rollback(ctx)

		var ebookID string
		var contentRaw []byte
		if err := tx.QueryRow(ctx, `SELECT id, COALESCE(content,'{}'::jsonb)::text FROM ebooks WHERE slug='main' FOR UPDATE`).Scan(&ebookID, &contentRaw); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var content any
		_ = json.Unmarshal(contentRaw, &content)

		key := storage.TimestampKey("ebook/versions/manual/")
		if _, err := uploader.UploadJSON(ctx, key, content); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var lbl *string
		if s := strings.TrimSpace(req.Label); s != "" {
			lbl = &s
		}
		var versionID string
		if err := tx.QueryRow(ctx, `INSERT INTO ebook_versions(ebook_id, kind, s3_key, label) VALUES ($1,'manual',$2,$3) RETURNING id`, ebookID, key, lbl).Scan(&versionID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		allowedPrefix := "ebooks/huashangdao/"
		keys := mediatools.ExtractMediaKeys(content, cdnBase, allowedPrefix)
		for _, mk := range keys {
			_, _ = tx.Exec(ctx, `INSERT INTO ebook_media_usage(media_key,manual_refs,last_seen_at) VALUES ($1,1,now()) ON CONFLICT (media_key) DO UPDATE SET manual_refs=ebook_media_usage.manual_refs+1,last_seen_at=now()`, mk)
			_, _ = tx.Exec(ctx, `INSERT INTO ebook_version_media(version_id,media_key) VALUES ($1,$2) ON CONFLICT DO NOTHING`, versionID, mk)
		}

		if err := tx.Commit(ctx); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "manual_version_created"})
	}
}

func PostPublishHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
		defer cancel()

		uploader, _ := storage.NewS3Uploader(ctx)
		if !uploader.Enabled() {
			c.JSON(http.StatusFailedDependency, gin.H{"error": "s3 not configured"})
			return
		}

		tx, err := db.Begin(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer tx.Rollback(ctx)

		var ebookID string
		var contentRaw []byte
		if err := tx.QueryRow(ctx, `SELECT id, COALESCE(content,'{}'::jsonb)::text FROM ebooks WHERE slug='main' FOR UPDATE`).Scan(&ebookID, &contentRaw); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var content any
		_ = json.Unmarshal(contentRaw, &content)

		key := storage.TimestampKey("ebook/versions/published/")
		if _, err := uploader.UploadJSON(ctx, key, content); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var versionID string
		if err := tx.QueryRow(ctx, `INSERT INTO ebook_versions(ebook_id, kind, s3_key, label) VALUES ($1,'published',$2,NULL) RETURNING id`, ebookID, key).Scan(&versionID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		allowedPrefix := "ebooks/huashangdao/"
		keys := mediatools.ExtractMediaKeys(content, cdnBase, allowedPrefix)
		for _, mk := range keys {
			_, _ = tx.Exec(ctx, `INSERT INTO ebook_media_usage(media_key,published_refs,last_seen_at) VALUES ($1,1,now()) ON CONFLICT (media_key) DO UPDATE SET published_refs=ebook_media_usage.published_refs+1,last_seen_at=now()`, mk)
			_, _ = tx.Exec(ctx, `INSERT INTO ebook_version_media(version_id,media_key) VALUES ($1,$2) ON CONFLICT DO NOTHING`, versionID, mk)
		}

		if err := tx.Commit(ctx); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "published"})
	}
}

// UploadImageHandler handles POST /api/ebook/upload-image
func UploadImageHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 30*time.Second)
		defer cancel()

		// Get the uploaded file
		file, header, err := c.Request.FormFile("image")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "No image file provided"})
			return
		}
		defer file.Close()

		// Validate file type
		contentType := header.Header.Get("Content-Type")
		if !strings.HasPrefix(contentType, "image/") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Only images are allowed"})
			return
		}

		// Read file content
		fileContent, err := io.ReadAll(file)
		if err != nil {
			log.Printf("Failed to read file: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file"})
			return
		}

		// Use the media bucket (same as catalog service) for ebook images
		// This ensures CloudFront can serve the images via assets.expotoworld.com
		bucket := "expotoworld-media"

		// Get AWS region
		region := os.Getenv("AWS_REGION")
		if region == "" {
			region = os.Getenv("AWS_DEFAULT_REGION")
		}
		if region == "" {
			region = "eu-central-1"
		}

		// Clear any existing credentials to use IAM role
		_ = os.Unsetenv("AWS_ACCESS_KEY_ID")
		_ = os.Unsetenv("AWS_SECRET_ACCESS_KEY")
		_ = os.Unsetenv("AWS_SESSION_TOKEN")

		// Load AWS config
		cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
		if err != nil {
			log.Printf("Failed to load AWS config: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to configure S3"})
			return
		}

		s3Client := s3.NewFromConfig(cfg)

		// Generate S3 object key
		ext := filepath.Ext(header.Filename)
		objectKey := fmt.Sprintf("ebooks/huashangdao/images/%d%s", time.Now().UnixNano(), ext)

		// Upload to S3
		_, err = s3Client.PutObject(ctx, &s3.PutObjectInput{
			Bucket:      &bucket,
			Key:         &objectKey,
			Body:        bytes.NewReader(fileContent),
			ContentType: &contentType,
		})
		if err != nil {
			log.Printf("Failed to upload to S3: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image"})
			return
		}

		// Build CloudFront URL
		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		imageURL := fmt.Sprintf("%s/%s", strings.TrimRight(cdnBase, "/"), objectKey)

		log.Printf("Successfully uploaded image to S3: %s", objectKey)
		c.JSON(http.StatusOK, gin.H{"url": imageURL})
	}
}

// DeleteImageHandler handles DELETE /api/ebook/delete-image
func DeleteImageHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
		defer cancel()

		// Get image URL from request body (robust to missing content-type) or query fallback
		var req struct {
			ImageURL string `json:"image_url"`
		}
		if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.ImageURL) == "" {
			if q := strings.TrimSpace(c.Query("image_url")); q != "" {
				req.ImageURL = q
			} else {
				// attempt raw body parse
				b, _ := io.ReadAll(c.Request.Body)
				_ = json.Unmarshal(b, &req)
				if strings.TrimSpace(req.ImageURL) == "" {
					c.JSON(http.StatusBadRequest, gin.H{"error": "image_url required"})
					return
				}
			}
		}

		// Extract S3 object key from CloudFront URL
		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		if !strings.HasPrefix(req.ImageURL, cdnBase) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid image URL"})
			return
		}
		objectKey := strings.TrimPrefix(req.ImageURL, strings.TrimRight(cdnBase, "/")+"/")

		// Only allow deletion under our ebook namespace (images today; future types too)
		if !strings.HasPrefix(objectKey, "ebooks/huashangdao/") {
			c.JSON(http.StatusForbidden, gin.H{"error": "Can only delete ebook media"})
			return
		}

		// Check usage (informational). We always schedule pending; cleanup will re-check and cancel if still referenced.
		var inAutosave bool
		var manualRefs, publishedRefs int
		_ = db.QueryRow(ctx, `SELECT in_autosave, manual_refs, published_refs FROM ebook_media_usage WHERE media_key=$1`, objectKey).Scan(&inAutosave, &manualRefs, &publishedRefs)

		// Schedule deletion with TTL
		ttlMin := 15
		if s := strings.TrimSpace(os.Getenv("MEDIA_DELETE_TTL_MIN")); s != "" {
			if n, e := strconv.Atoi(s); e == nil && n > 0 {
				ttlMin = n
			}
		}
		_, _ = db.Exec(ctx, `INSERT INTO ebook_media_pending_deletion(media_key,requested_at,not_before,attempts,last_checked_at) VALUES ($1, now(), now() + ($2::int * interval '1 minute'), 0, NULL) ON CONFLICT (media_key) DO UPDATE SET requested_at=now(), not_before=now() + ($2::int * interval '1 minute')`, objectKey, ttlMin)

		c.JSON(http.StatusOK, gin.H{"status": "scheduled", "key": objectKey, "ttl_minutes": ttlMin})
	}
}
