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
