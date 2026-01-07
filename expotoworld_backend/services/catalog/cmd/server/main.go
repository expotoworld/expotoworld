// Package main is the entry point for the catalog service.
// STATUS: SCAFFOLD ONLY - Implementation needed.
// See: docs/TODO/Backend Handoff - Next Agent Instructions.md
package main

import (
"context"
"log/slog"
"net/http"
"os"
"os/signal"
"strconv"
"syscall"
"time"

"github.com/expotoworld/expotoworld_backend/pkg/config"
"github.com/expotoworld/expotoworld_backend/pkg/database"
"github.com/expotoworld/expotoworld_backend/pkg/httputil"
"github.com/expotoworld/expotoworld_backend/pkg/logger"
"github.com/gin-gonic/gin"
)

const (
serviceName    = "catalog-service"
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

	cfg, err := config.Load()
	if err != nil {
		return err
	}

	log := logger.New(logger.Config{
Level:       cfg.Log.Level,
Format:      cfg.Log.Format,
ServiceName: serviceName,
Environment: cfg.App.Env,
})

	log.Info("Starting catalog service",
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

	// TODO: Initialize repositories
	// TODO: Initialize services
	// TODO: Initialize handlers

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

	// TODO: Setup API routes for products and categories

	port := strconv.Itoa(cfg.Server.CatalogPort)
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
