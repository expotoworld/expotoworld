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
func UploadImageHandler(db *pgxpool.Pool) gin.HandlerFunc {
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

		// Upsert into ebook_media_assets for consistency with new media endpoint
		if db != nil {
			_, _ = db.Exec(ctx, `INSERT INTO ebook_media_assets(media_key, file_type, mime_type, file_size, created_at, updated_at)
				VALUES ($1,'image',$2,$3, now(), now())
				ON CONFLICT (media_key) DO UPDATE SET file_type='image', mime_type=EXCLUDED.mime_type, file_size=EXCLUDED.file_size, updated_at=now()`,
				objectKey, contentType, int64(len(fileContent)),
			)
		}

		log.Printf("Successfully uploaded image to S3: %s", objectKey)
		c.JSON(http.StatusOK, gin.H{"url": imageURL})
	}
}

// UploadMediaHandler handles POST /api/ebook/upload-media for image, video, and audio
func UploadMediaHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 45*time.Second)
		defer cancel()

		// Accept file under field name "file"
		file, header, err := c.Request.FormFile("file")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "No file provided (expected field 'file')"})
			return
		}
		defer file.Close()

		fileBytes, err := io.ReadAll(file)
		if err != nil {
			log.Printf("read file: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file"})
			return
		}

		// Determine type: explicit form value takes precedence, else derive from Content-Type
		typeHint := strings.ToLower(strings.TrimSpace(c.PostForm("type")))
		contentType := header.Header.Get("Content-Type")
		if contentType == "" {
			contentType = http.DetectContentType(fileBytes)
		}

		var category string // image|video|audio
		if typeHint == "image" || typeHint == "video" || typeHint == "audio" {
			category = typeHint
		} else if strings.HasPrefix(contentType, "image/") {
			category = "image"
		} else if strings.HasPrefix(contentType, "video/") {
			category = "video"
		} else if strings.HasPrefix(contentType, "audio/") {
			category = "audio"
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Unsupported media type"})
			return
		}

		// Validate allow-lists
		allowedImages := map[string]bool{"image/jpeg": true, "image/jpg": true, "image/png": true, "image/svg+xml": true, "image/gif": true, "image/heic": true}
		allowedVideos := map[string]bool{"video/mp4": true, "video/quicktime": true}
		allowedAudio := map[string]bool{"audio/mpeg": true, "audio/mp4": true, "audio/x-m4a": true, "audio/wav": true}
		switch category {
		case "image":
			if !allowedImages[strings.ToLower(contentType)] {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid image type"})
				return
			}
		case "video":
			if !allowedVideos[strings.ToLower(contentType)] {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video type (allowed: MP4, MOV)"})
				return
			}
		case "audio":
			if !allowedAudio[strings.ToLower(contentType)] {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid audio type (allowed: MP3, M4A, WAV)"})
				return
			}
		}

		bucket := "expotoworld-media"
		region := os.Getenv("AWS_REGION")
		if region == "" {
			region = os.Getenv("AWS_DEFAULT_REGION")
		}
		if region == "" {
			region = "eu-central-1"
		}

		_ = os.Unsetenv("AWS_ACCESS_KEY_ID")
		_ = os.Unsetenv("AWS_SECRET_ACCESS_KEY")
		_ = os.Unsetenv("AWS_SESSION_TOKEN")

		cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
		if err != nil {
			log.Printf("aws cfg: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to configure S3"})
			return
		}
		s3Client := s3.NewFromConfig(cfg)

		// Determine prefix and key
		var prefix string
		switch category {
		case "image":
			prefix = "ebooks/huashangdao/images/"
		case "video":
			prefix = "ebooks/huashangdao/videos/"
		case "audio":
			prefix = "ebooks/huashangdao/audio/"
		}
		ext := filepath.Ext(header.Filename)
		if ext == "" {
			// best-effort extension based on content type
			if category == "image" && strings.Contains(contentType, "png") {
				ext = ".png"
			}
			if category == "image" && (strings.Contains(contentType, "jpeg") || strings.Contains(contentType, "jpg")) {
				ext = ".jpg"
			}
			if category == "image" && strings.Contains(contentType, "gif") {
				ext = ".gif"
			}
			if category == "image" && strings.Contains(contentType, "svg") {
				ext = ".svg"
			}
			if category == "image" && strings.Contains(contentType, "heic") {
				ext = ".heic"
			}
			if category == "video" && strings.Contains(contentType, "mp4") {
				ext = ".mp4"
			}
			if category == "video" && strings.Contains(contentType, "quicktime") {
				ext = ".mov"
			}
			if category == "audio" && (strings.Contains(contentType, "mpeg")) {
				ext = ".mp3"
			}
			if category == "audio" && (strings.Contains(contentType, "mp4") || strings.Contains(contentType, "x-m4a")) {
				ext = ".m4a"
			}
			if category == "audio" && strings.Contains(contentType, "wav") {
				ext = ".wav"
			}
		}
		objectKey := fmt.Sprintf("%s%d%s", prefix, time.Now().UnixNano(), ext)

		// Upload
		_, err = s3Client.PutObject(ctx, &s3.PutObjectInput{
			Bucket:      &bucket,
			Key:         &objectKey,
			Body:        bytes.NewReader(fileBytes),
			ContentType: &contentType,
		})
		if err != nil {
			log.Printf("s3 put: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload media"})
			return
		}

		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		url := fmt.Sprintf("%s/%s", strings.TrimRight(cdnBase, "/"), objectKey)
		log.Printf("[UPLOAD media] cat=%s ct=%s name=%s size=%d key=%s", category, contentType, header.Filename, len(fileBytes), objectKey)

		// Upsert metadata (no duration)
		if db != nil {
			tag, err := db.Exec(ctx, `INSERT INTO ebook_media_assets(media_key, file_type, mime_type, file_size, created_at, updated_at)
				VALUES ($1,$2,$3,$4, now(), now())
				ON CONFLICT (media_key) DO UPDATE SET file_type=EXCLUDED.file_type, mime_type=EXCLUDED.mime_type, file_size=EXCLUDED.file_size, updated_at=now()`,
				objectKey, category, contentType, int64(len(fileBytes)),
			)
			if err != nil {
				log.Printf("[UPLOAD media] upsert assets err=%v", err)
			} else {
				log.Printf("[UPLOAD media] upsert assets ok rows=%d", tag.RowsAffected())
			}
		}

		c.JSON(http.StatusOK, gin.H{"url": url, "key": objectKey, "type": category, "mime_type": contentType, "size": len(fileBytes)})
	}
}

// DeleteMediaHandler handles DELETE /api/ebook/delete-media for any media type
func DeleteMediaHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
		defer cancel()

		var req struct {
			MediaURL string `json:"media_url"`
			ImageURL string `json:"image_url"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			b, _ := io.ReadAll(c.Request.Body)
			_ = json.Unmarshal(b, &req)
		}
		urlStr := strings.TrimSpace(req.MediaURL)
		if urlStr == "" {
			urlStr = strings.TrimSpace(req.ImageURL)
		}
		if urlStr == "" {
			urlStr = strings.TrimSpace(c.Query("media_url"))
		}
		if urlStr == "" {
			urlStr = strings.TrimSpace(c.Query("image_url"))
		}
		if urlStr == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "media_url required"})
			return
		}

		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		if !strings.HasPrefix(urlStr, strings.TrimRight(cdnBase, "/")+"/") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid media URL"})
			return
		}
		objectKey := strings.TrimPrefix(urlStr, strings.TrimRight(cdnBase, "/")+"/")
		if !strings.HasPrefix(objectKey, "ebooks/huashangdao/") {
			c.JSON(http.StatusForbidden, gin.H{"error": "Can only delete ebook media"})
			return
		}

		// Guard: only enqueue when not referenced anywhere and not in autosave
		var inAutosave bool
		var manualRefs, publishedRefs int
		err := db.QueryRow(ctx, `SELECT in_autosave, manual_refs, published_refs FROM ebook_media_usage WHERE media_key=$1`, objectKey).Scan(&inAutosave, &manualRefs, &publishedRefs)
		if err == nil {
			if inAutosave || manualRefs > 0 || publishedRefs > 0 {
				c.JSON(http.StatusOK, gin.H{"status": "skipped", "reason": "still_referenced", "key": objectKey})
				return
			}
		}

		// Schedule deletion (same TTL logic as image)
		ttlMin := 15
		if s := strings.TrimSpace(os.Getenv("MEDIA_DELETE_TTL_MIN")); s != "" {
			if n, e := strconv.Atoi(s); e == nil && n > 0 {
				ttlMin = n
			}
		}
		_, _ = db.Exec(ctx, `INSERT INTO ebook_media_pending_deletion(media_key,requested_at,not_before,attempts,last_checked_at)
			VALUES ($1, now(), now() + ($2::int * interval '1 minute'), 0, NULL)
			ON CONFLICT (media_key) DO UPDATE SET requested_at=now(), not_before=now() + ($2::int * interval '1 minute')`, objectKey, ttlMin)

		c.JSON(http.StatusOK, gin.H{"status": "scheduled", "key": objectKey, "ttl_minutes": ttlMin})
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

		// Guard: only enqueue when not referenced anywhere and not in autosave
		if inAutosave || manualRefs > 0 || publishedRefs > 0 {
			c.JSON(http.StatusOK, gin.H{"status": "skipped", "reason": "still_referenced", "key": objectKey})
			return
		}

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

// GetVersionContentHandler returns JSON content for a specific version id
func GetVersionContentHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := strings.TrimSpace(c.Param("id"))
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id required"})
			return
		}
		ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
		defer cancel()

		u, _ := storage.NewS3Uploader(ctx)
		if !u.Enabled() {
			c.JSON(http.StatusFailedDependency, gin.H{"error": "s3 not configured"})
			return
		}

		var key string
		if err := db.QueryRow(ctx, `SELECT ev.s3_key
			FROM ebook_versions ev
			JOIN ebooks e ON e.id=ev.ebook_id
			WHERE e.slug='main' AND ev.id=$1`, id).Scan(&key); err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}
		b, err := u.GetJSON(ctx, key)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var content any
		_ = json.Unmarshal(b, &content)
		c.JSON(http.StatusOK, gin.H{"id": id, "content": content})
	}
}

// RestoreVersionHandler replaces autosave content with the version's JSON and updates media usage
func RestoreVersionHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := strings.TrimSpace(c.Param("id"))
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id required"})
			return
		}
		ctx, cancel := context.WithTimeout(c.Request.Context(), 15*time.Second)
		defer cancel()

		u, _ := storage.NewS3Uploader(ctx)
		if !u.Enabled() {
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
		var oldContent sql.NullString
		if err := tx.QueryRow(ctx, `SELECT id, content::text FROM ebooks WHERE slug='main' FOR UPDATE`).Scan(&ebookID, &oldContent); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var key string
		if err := tx.QueryRow(ctx, `SELECT s3_key FROM ebook_versions WHERE id=$1 AND ebook_id=$2`, id, ebookID).Scan(&key); err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}

		b, err := u.GetJSON(ctx, key)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var newContent any
		_ = json.Unmarshal(b, &newContent)

		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		allowedPrefix := "ebooks/huashangdao/"
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
		if _, err := tx.Exec(ctx, `UPDATE ebooks SET content=$1::jsonb, updated_at=now() WHERE id=$2`, string(b), ebookID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		// Maintain usage flags
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
		c.JSON(http.StatusOK, gin.H{"status": "restored"})
	}
}

// DeleteVersionHandler removes a version, updates media refs, and deletes JSON from S3 (post-commit)
func DeleteVersionHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := strings.TrimSpace(c.Param("id"))
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id required"})
			return
		}
		ctx, cancel := context.WithTimeout(c.Request.Context(), 15*time.Second)
		defer cancel()

		u, _ := storage.NewS3Uploader(ctx)
		if !u.Enabled() {
			c.JSON(http.StatusFailedDependency, gin.H{"error": "s3 not configured"})
			return
		}

		tx, err := db.Begin(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer tx.Rollback(ctx)

		// Ensure version belongs to our ebook and capture s3 key BEFORE deleting rows
		var kind, key, ebookID string
		if err := tx.QueryRow(ctx, `SELECT ev.kind, ev.s3_key, ev.ebook_id
			FROM ebook_versions ev JOIN ebooks e ON e.id=ev.ebook_id
			WHERE e.slug='main' AND ev.id=$1`, id).Scan(&kind, &key, &ebookID); err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}

		// Load mapped media keys (handle errors explicitly)
		mediaKeys := []string{}
		if rows, qerr := tx.Query(ctx, `SELECT media_key FROM ebook_version_media WHERE version_id=$1`, id); qerr == nil {
			for rows.Next() {
				var mk string
				if err := rows.Scan(&mk); err == nil {
					mediaKeys = append(mediaKeys, mk)
				}
			}
			rows.Close()
		}

		for _, mk := range mediaKeys {
			if kind == "manual" {
				_, _ = tx.Exec(ctx, `UPDATE ebook_media_usage SET manual_refs=GREATEST(manual_refs-1,0), last_seen_at=now() WHERE media_key=$1`, mk)
			} else {
				_, _ = tx.Exec(ctx, `UPDATE ebook_media_usage SET published_refs=GREATEST(published_refs-1,0), last_seen_at=now() WHERE media_key=$1`, mk)
			}
			// If now unused anywhere, schedule deletion
			var inAutosave bool
			var mRef, pRef int
			_ = tx.QueryRow(ctx, `SELECT in_autosave, manual_refs, published_refs FROM ebook_media_usage WHERE media_key=$1`, mk).Scan(&inAutosave, &mRef, &pRef)
			if !inAutosave && mRef == 0 && pRef == 0 {
				ttlMin := 15
				if s := strings.TrimSpace(os.Getenv("MEDIA_DELETE_TTL_MIN")); s != "" {
					if n, e := strconv.Atoi(s); e == nil && n > 0 {
						ttlMin = n
					}
				}
				_, _ = tx.Exec(ctx, `INSERT INTO ebook_media_pending_deletion(media_key,requested_at,not_before,attempts,last_checked_at)
					VALUES ($1, now(), now() + ($2::int * interval '1 minute'), 0, NULL)
					ON CONFLICT (media_key) DO UPDATE SET requested_at=now(), not_before=now() + ($2::int * interval '1 minute')`, mk, ttlMin)
			}
		}
		// Remove mapping rows then the version row (explicitly for both kinds)
		if _, err := tx.Exec(ctx, `DELETE FROM ebook_version_media WHERE version_id=$1`, id); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if _, err := tx.Exec(ctx, `DELETE FROM ebook_versions WHERE id=$1`, id); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		if err := tx.Commit(ctx); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		// Delete object outside transaction (applies to BOTH manual and published)
		if key != "" {
			if err := u.DeleteObject(ctx, key); err != nil {
				log.Printf("[EBOOK] s3 delete failed key=%s err=%v", key, err)
			}
		}
		c.JSON(http.StatusOK, gin.H{"status": "deleted"})
	}
}

// PublishFromManualVersionHandler creates a published version by cloning a manual version
func PublishFromManualVersionHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := strings.TrimSpace(c.Param("id"))
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id required"})
			return
		}
		var req struct {
			Label string `json:"label"`
		}
		_ = c.ShouldBindJSON(&req)
		ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
		defer cancel()

		u, _ := storage.NewS3Uploader(ctx)
		if !u.Enabled() {
			c.JSON(http.StatusFailedDependency, gin.H{"error": "s3 not configured"})
			return
		}

		tx, err := db.Begin(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer tx.Rollback(ctx)

		// Ensure it is a manual version under our ebook
		var ebookID, kind, key string
		if err := tx.QueryRow(ctx, `SELECT ev.ebook_id, ev.kind, ev.s3_key
			FROM ebook_versions ev JOIN ebooks e ON e.id=ev.ebook_id
			WHERE e.slug='main' AND ev.id=$1`, id).Scan(&ebookID, &kind, &key); err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}
		if kind != "manual" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "not a manual version"})
			return
		}

		b, err := u.GetJSON(ctx, key)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var content any
		_ = json.Unmarshal(b, &content)

		pubKey := storage.TimestampKey("ebook/versions/published/")
		if _, err := u.UploadJSON(ctx, pubKey, content); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		var lbl *string
		if s := strings.TrimSpace(req.Label); s != "" {
			lbl = &s
		}
		var newID string
		if err := tx.QueryRow(ctx, `INSERT INTO ebook_versions(ebook_id, kind, s3_key, label) VALUES ($1,'published',$2,$3) RETURNING id`, ebookID, pubKey, lbl).Scan(&newID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		cdnBase := os.Getenv("ASSETS_CDN_BASE_URL")
		if cdnBase == "" {
			cdnBase = "https://assets.expotoworld.com"
		}
		allowedPrefix := "ebooks/huashangdao/"
		for _, mk := range mediatools.ExtractMediaKeys(content, cdnBase, allowedPrefix) {
			_, _ = tx.Exec(ctx, `INSERT INTO ebook_media_usage(media_key,published_refs,last_seen_at) VALUES ($1,1,now()) ON CONFLICT (media_key) DO UPDATE SET published_refs=ebook_media_usage.published_refs+1,last_seen_at=now()`, mk)
			_, _ = tx.Exec(ctx, `INSERT INTO ebook_version_media(version_id,media_key) VALUES ($1,$2) ON CONFLICT DO NOTHING`, newID, mk)
		}

		if err := tx.Commit(ctx); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "published", "id": newID})
	}
}

// PatchVersionLabelHandler updates the label of a version (manual or published) under the main ebook
func PatchVersionLabelHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := strings.TrimSpace(c.Param("id"))
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id required"})
			return
		}
		var req struct {
			Label string `json:"label"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid JSON"})
			return
		}
		s := strings.TrimSpace(req.Label)
		var label *string
		if s != "" {
			label = &s
		}

		ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
		defer cancel()
		cmd, err := db.Exec(ctx, `UPDATE ebook_versions ev SET label=$1 FROM ebooks e WHERE ev.ebook_id=e.id AND e.slug='main' AND ev.id=$2`, label, id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if cmd.RowsAffected() == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "renamed"})
	}
}
