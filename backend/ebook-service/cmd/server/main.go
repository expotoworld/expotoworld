package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"

	api "github.com/expotoworld/expotoworld/backend/ebook-service/internal/api"
	"github.com/expotoworld/expotoworld/backend/ebook-service/internal/ebookschema"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file if it exists
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	port := getEnv("PORT", "8084")
	dbURL := getEnv("DATABASE_URL", "")
	if dbURL == "" {
		// Compose from discrete envs if provided (Terraform style)
		host := getEnv("DB_HOST", "")
		user := getEnv("DB_USER", "")
		name := getEnv("DB_NAME", "")
		pwd := getEnv("DB_PASSWORD", "")
		ssl := getEnv("DB_SSLMODE", "require")
		portNum := getEnv("DB_PORT", "5432")
		if host != "" && user != "" && name != "" && pwd != "" {
			dbURL = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", user, url.QueryEscape(pwd), host, portNum, name, ssl)
		}
	}
	if dbURL == "" {
		log.Println("WARNING: No database configuration; set DATABASE_URL or DB_* envs")
	}

	// DB pool
	var pool *pgxpool.Pool
	if dbURL != "" {
		cfg, err := pgxpool.ParseConfig(dbURL)
		if err != nil {
			log.Fatalf("failed to parse DATABASE_URL: %v", err)
		}
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		pool, err = pgxpool.NewWithConfig(ctx, cfg)
		if err != nil {
			log.Fatalf("failed to create pgx pool: %v", err)
		}
		defer pool.Close()

		// Initialize media schema (idempotent)
		if err := ebookschema.Init(ctx, pool); err != nil {
			log.Printf("[EBOOK] Warning: media schema init failed: %v", err)
		}
	}

	r := gin.Default()

	// CORS restricted to editor origin if provided
	editorOrigin := getEnv("EDITOR_ORIGIN", "")
	corsCfg := cors.Config{AllowMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}, AllowHeaders: []string{"Authorization", "Content-Type"}}
	if editorOrigin != "" {
		corsCfg.AllowOrigins = []string{editorOrigin}
	} else {
		corsCfg.AllowAllOrigins = true
	}
	r.Use(cors.New(corsCfg))

	// Health
	r.GET("/health", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "ok"}) })
	r.GET("/live", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "ok"}) })

	// Public/app-auth routes (require JWT but any role is fine): published reading
	app := r.Group("/api")
	app.Use(api.JWTOptionalMiddleware()) // Accepts JWT if provided; we will enforce on specific routes
	{
		app.GET("/ebook/versions", api.RequireJWT(), api.GetEbookVersionsHandler(pool))
	}

	// Author-only routes (draft edits)
	author := r.Group("/api")
	author.Use(api.JWTMiddleware(), api.RequireAuthor())
	{
		author.GET("/ebook", api.GetDraftEbookHandler(pool))
		author.PUT("/ebook", api.PutAutosaveEbookHandler(pool))
		author.POST("/ebook/versions", api.PostManualVersionHandler(pool))
		author.POST("/ebook/publish", api.PostPublishHandler(pool))
		author.POST("/ebook/upload-image", api.UploadImageHandler())
		// Guarded delete now needs DB
		author.DELETE("/ebook/delete-image", api.DeleteImageHandler(pool))

		// Dev-only admin tools inside editor (gated by env in handlers)
		author.POST("/ebook/admin/reindex", api.AdminReindexHandler(pool))
		author.GET("/ebook/admin/inspect", api.AdminInspectMediaHandler(pool))
		author.GET("/ebook/admin/pending", api.AdminListPendingHandler(pool))
		author.GET("/ebook/admin/media-list", api.AdminListMediaHandler(pool))

	}

	log.Printf("ebook-service listening on :%s", port)
	if err := r.Run(fmt.Sprintf(":%s", port)); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func getEnv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
