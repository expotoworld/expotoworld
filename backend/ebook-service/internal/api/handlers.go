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
	"github.com/expomadeinworld/expotoworld/backend/ebook-service/internal/storage"
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

		// Autosave: single-file strategy — only update ebooks.content (no S3 snapshot, no version row)

		b, _ := json.Marshal(newContent)
		if _, err := tx.Exec(ctx, `UPDATE ebooks SET content=$1::jsonb, updated_at=now() WHERE id=$2`, string(b), ebookID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
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
		if _, err := tx.Exec(ctx, `INSERT INTO ebook_versions(ebook_id, kind, s3_key, label) VALUES ($1,'manual',$2,$3)`, ebookID, key, lbl); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
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
		if _, err := tx.Exec(ctx, `INSERT INTO ebook_versions(ebook_id, kind, s3_key, label) VALUES ($1,'published',$2,NULL)`, ebookID, key); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
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

		// Get S3 bucket from environment
		bucket := os.Getenv("EBOOK_S3_BUCKET")
		if bucket == "" {
			c.JSON(http.StatusFailedDependency, gin.H{"error": "S3 not configured"})
			return
		}

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
		objectKey := fmt.Sprintf("ebook/images/%d%s", time.Now().UnixNano(), ext)

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
