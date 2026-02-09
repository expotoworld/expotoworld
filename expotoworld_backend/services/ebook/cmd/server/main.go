// Package main is the entry point for the ebook service.
package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/expotoworld/expotoworld_backend/pkg/auth"
	appconfig "github.com/expotoworld/expotoworld_backend/pkg/config"
	"github.com/expotoworld/expotoworld_backend/pkg/database"
	"github.com/expotoworld/expotoworld_backend/pkg/httputil"
	"github.com/expotoworld/expotoworld_backend/pkg/logger"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/handler"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/repository/postgres"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/schema"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/service"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/storage"
	"github.com/gin-gonic/gin"
)

const (
	serviceName    = "ebook-service"
	serviceVersion = "1.0.0"

	// S3 bucket configuration
	defaultVersionsBucket = "expotoworld-ebook-versions"
	defaultMediaBucket    = "expotoworld-media"
	defaultMediaBasePath  = "ebooks/huashangdao"
	defaultCDNBaseURL     = "https://assets.expotoworld.com"
	defaultPendingTTL     = 15 // minutes
)

func main() {
	if err := run(); err != nil {
		slog.Error("Service failed", "error", err)
		os.Exit(1)
	}
}

func run() error {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cfg, err := appconfig.Load()
	if err != nil {
		return err
	}

	log := logger.New(logger.Config{
		Level:       cfg.Log.Level,
		Format:      cfg.Log.Format,
		ServiceName: serviceName,
		Environment: cfg.App.Env,
	})

	log.Info("Starting ebook service",
		"version", serviceVersion,
		"environment", cfg.App.Env,
	)

	// Debug: Log database endpoint (mask password for security)
	if cfg.App.Debug {
		// Extract just the host from the database URL for logging
		dbURL := cfg.Database.URL
		if len(dbURL) > 0 {
			// Find the @ symbol to get the host portion
			atIdx := -1
			for i, c := range dbURL {
				if c == '@' {
					atIdx = i
					break
				}
			}
			if atIdx > 0 && atIdx < len(dbURL)-1 {
				hostPart := dbURL[atIdx+1:]
				// Truncate at first / to get just host:port
				for i, c := range hostPart {
					if c == '/' {
						hostPart = hostPart[:i]
						break
					}
				}
				log.Debug("Database configuration", "host", hostPart)
			}
		}
	}

	// Initialize database pool
	pool, err := database.NewPool(ctx, &database.PoolConfig{
		URL:             cfg.Database.URL,
		MaxConns:        cfg.Database.MaxConns,
		MinConns:        cfg.Database.MinConns,
		MaxConnLifetime: cfg.Database.MaxConnLifetime,
		MaxConnIdleTime: cfg.Database.MaxConnIdleTime,
	})
	if err != nil {
		return err
	}
	defer pool.Close()

	log.Info("Database connection established")

	// Get the underlying pgxpool.Pool
	pgxPool := pool.Pool

	// Initialize schema (idempotent)
	if err := schema.Init(ctx, pgxPool); err != nil {
		log.Warn("Schema initialization warning", "error", err)
	}

	// Verify schema
	if err := schema.Verify(ctx, pgxPool); err != nil {
		return err
	}

	// Initialize AWS S3 client
	awsCfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return err
	}
	s3Client := s3.NewFromConfig(awsCfg)

	// Get configuration from environment or use defaults
	versionsBucket := getEnvOrDefault("EBOOK_VERSIONS_BUCKET", defaultVersionsBucket)
	mediaBucket := getEnvOrDefault("EBOOK_MEDIA_BUCKET", defaultMediaBucket)
	mediaBasePath := getEnvOrDefault("EBOOK_MEDIA_BASE_PATH", defaultMediaBasePath)
	cdnBaseURL := getEnvOrDefault("CDN_BASE_URL", defaultCDNBaseURL)
	_ = getEnvIntOrDefault("EBOOK_PENDING_TTL_MINUTES", defaultPendingTTL) // Reserved for future use

	// Initialize storage client (using media bucket as default)
	storageClient := storage.NewS3Client(s3Client, mediaBucket)

	// Initialize repositories (using pgxPool)
	ebookRepo := postgres.NewEbookRepository(pgxPool)
	versionRepo := postgres.NewVersionRepository(pgxPool)
	mediaUsageRepo := postgres.NewMediaUsageRepository(pgxPool)
	mediaPendingRepo := postgres.NewMediaPendingRepository(pgxPool)
	versionMediaRepo := postgres.NewVersionMediaRepository(pgxPool)
	mediaAssetRepo := postgres.NewMediaAssetRepository(pgxPool)

	// Initialize services
	ebookService := service.NewEbookService(
		pgxPool,
		ebookRepo,
		versionRepo,
		mediaUsageRepo,
		storageClient,
		cdnBaseURL,
	)

	versionService := service.NewVersionService(
		pgxPool,
		ebookRepo,
		versionRepo,
		mediaUsageRepo,
		versionMediaRepo,
		storageClient,
		versionsBucket,
		cdnBaseURL,
	)

	mediaService := service.NewMediaService(
		pgxPool,
		mediaUsageRepo,
		mediaPendingRepo,
		mediaAssetRepo,
		storageClient,
		cdnBaseURL,
		mediaBucket,
		mediaBasePath,
	)

	// Initialize handlers
	ebookHandler := handler.NewEbookHandler(ebookService)
	versionHandler := handler.NewVersionHandler(versionService)
	mediaHandler := handler.NewMediaHandler(mediaService)
	adminHandler := handler.NewAdminHandler(mediaService)
	healthHandler := handler.NewHealthHandler()

	// Initialize JWKS validator for authentication
	// Use auth service's JWKS endpoint for JWT validation
	// Note: JWKS is at root level, not under /api/v1/auth
	jwksURL := getEnvOrDefault("JWKS_URL", "http://localhost:8081/.well-known/jwks.json")
	jwtIssuer := getEnvOrDefault("JWT_ISSUER", "expotoworld") // Must match auth service issuer
	jwtAudience := getEnvOrDefault("JWT_AUDIENCE", "")        // Empty means skip audience validation
	log.Info("initializing auth validator",
		"jwks_url", jwksURL,
		"jwt_issuer", jwtIssuer,
		"jwt_audience", jwtAudience,
	)
	validator, err := auth.NewValidator(auth.ValidatorConfig{
		JWKSURL:  jwksURL,
		Issuer:   jwtIssuer,
		Audience: jwtAudience,
	})
	if err != nil {
		return fmt.Errorf("initialize auth validator: %w", err)
	}

	// Enable debug logging for auth middleware in non-production environments
	authDebugEnabled := cfg.App.Env != "production"
	authMiddleware := auth.GinAuthMiddleware(&auth.GinMiddlewareConfig{
		Validator: validator,
		Debug:     authDebugEnabled,
		Logger:    log,
	})

	if cfg.App.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(logger.GinMiddleware(log))

	corsConfig := &httputil.CORSConfig{
		AllowedOrigins:   cfg.CORS.AllowedOrigins,
		AllowedMethods:   cfg.CORS.AllowedMethods,
		AllowedHeaders:   cfg.CORS.AllowedHeaders,
		AllowCredentials: cfg.CORS.AllowCredentials,
		MaxAge:           cfg.CORS.MaxAge,
	}
	router.Use(httputil.CORSMiddleware(corsConfig))

	// Health endpoints (no auth)
	router.GET("/live", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "alive"})
	})
	router.GET("/ready", func(c *gin.Context) {
		if err := pool.Ping(ctx); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "not ready", "error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ready"})
	})
	router.GET("/health", healthHandler.Health)

	// API routes
	api := router.Group("/api/ebook")
	{
		// Protected routes (require authentication)
		protected := api.Group("")
		protected.Use(authMiddleware)
		protected.Use(auth.RequireAuthor())
		{
			// Draft operations
			protected.GET("/draft/:ebook_id", ebookHandler.GetDraft)
			protected.POST("/draft/:ebook_id", ebookHandler.SaveDraft)

			// Version operations
			protected.GET("/:ebook_id/versions", versionHandler.ListVersions)
			protected.POST("/:ebook_id/versions", versionHandler.CreateVersion)
			protected.GET("/:ebook_id/versions/:version_id/content", versionHandler.GetVersionContent)
			protected.POST("/:ebook_id/versions/:version_id/publish", versionHandler.PublishVersion)
			protected.POST("/:ebook_id/versions/:version_id/restore", versionHandler.RestoreVersion)
			protected.DELETE("/:ebook_id/versions/:version_id", versionHandler.DeleteVersion)
			protected.PATCH("/:ebook_id/versions/:version_id", versionHandler.UpdateVersionLabel)

			// Media operations
			protected.POST("/:ebook_id/media", mediaHandler.UploadMedia)
			protected.DELETE("/:ebook_id/media", mediaHandler.DeleteMedia)
		}

		// Admin routes (require author role - authors manage their own ebook media)
		admin := api.Group("/admin")
		admin.Use(authMiddleware)
		admin.Use(auth.RequireAuthor())
		{
			admin.GET("/pending", adminHandler.ListPendingDeletions)
		}
	}

	port := strconv.Itoa(cfg.Server.EbookPort)
	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
	}

	go func() {
		log.Info("Server listening", "port", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Error("Server failed", "error", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down server...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Error("Server forced to shutdown", "error", err)
		return err
	}

	log.Info("Server stopped gracefully")
	return nil
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvIntOrDefault(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
