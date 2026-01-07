// Package main is the entry point for the auth service.
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
	"github.com/aws/aws-sdk-go-v2/service/ses"
	pkgconfig "github.com/expotoworld/expotoworld_backend/pkg/config"
	"github.com/expotoworld/expotoworld_backend/pkg/database"
	"github.com/expotoworld/expotoworld_backend/pkg/httputil"
	"github.com/expotoworld/expotoworld_backend/pkg/logger"
	"github.com/expotoworld/expotoworld_backend/services/auth/internal/email"
	"github.com/expotoworld/expotoworld_backend/services/auth/internal/handler"
	"github.com/expotoworld/expotoworld_backend/services/auth/internal/repository/postgres"
	"github.com/expotoworld/expotoworld_backend/services/auth/internal/service"
	"github.com/gin-gonic/gin"
)

const (
	serviceName    = "auth-service"
	serviceVersion = "1.0.0"
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

	cfg, err := pkgconfig.Load()
	if err != nil {
		return err
	}

	log := logger.New(logger.Config{
		Level:       cfg.Log.Level,
		Format:      cfg.Log.Format,
		ServiceName: serviceName,
		Environment: cfg.App.Env,
	})

	log.Info("Starting auth service",
		"version", serviceVersion,
		"environment", cfg.App.Env,
	)

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

	// Initialize AWS services
	awsCfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(cfg.AWS.Region))
	if err != nil {
		log.Error("Failed to load AWS config", "error", err)
		return err
	}

	// JWT private key is already loaded by pkg/config from Secrets Manager
	jwtPrivateKey := cfg.JWT.PrivateKeyPEM
	if jwtPrivateKey == "" {
		log.Error("JWT private key is not configured")
		return fmt.Errorf("JWT_PRIVATE_KEY_PEM or AWS_SECRET_JWT_PRIVATE is required")
	}
	log.Info("JWT private key loaded")

	// Initialize repositories
	userRepo := postgres.NewUserRepository(pool.Pool)
	codeRepo := postgres.NewVerificationCodeRepository(pool.Pool)
	tokenRepo := postgres.NewRefreshTokenRepository(pool.Pool)
	rateLimitRepo := postgres.NewRateLimitRepository(pool.Pool)

	// Initialize email service
	sesClient := ses.NewFromConfig(awsCfg)
	emailService := email.NewService(sesClient, email.Config{
		FromEmail: cfg.AWS.SESSenderEmail,
		FromName:  cfg.AWS.SESSenderName,
		Region:    cfg.AWS.Region,
	}, log.Logger)

	// Initialize auth service
	authServiceCfg := service.DefaultConfig()
	authServiceCfg.JWTPrivateKey = jwtPrivateKey
	authServiceCfg.JWTIssuer = cfg.JWT.Issuer

	authService, err := service.NewAuthService(
		userRepo,
		codeRepo,
		tokenRepo,
		rateLimitRepo,
		emailService,
		authServiceCfg,
		log.Logger,
	)
	if err != nil {
		log.Error("Failed to create auth service", "error", err)
		return err
	}

	// Initialize HTTP handler
	authHandler := handler.NewAuthHandler(authService, log.Logger)

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

	// Register auth routes
	authHandler.RegisterRoutes(router)

	port := strconv.Itoa(cfg.Server.AuthPort)
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
