package httputil

import (
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CORSConfig configures CORS middleware.
type CORSConfig struct {
	AllowedOrigins   []string
	AllowedMethods   []string
	AllowedHeaders   []string
	ExposedHeaders   []string
	AllowCredentials bool
	MaxAge           int
}

// DefaultCORSConfig returns a secure default CORS configuration.
func DefaultCORSConfig() *CORSConfig {
	return &CORSConfig{
		AllowedOrigins: []string{},
		AllowedMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowedHeaders: []string{
			"Accept",
			"Authorization",
			"Content-Type",
			"X-Correlation-ID",
			"X-Request-ID",
			"X-Require-Existing",
			"X-Require-Role",
		},
		ExposedHeaders: []string{
			"X-Correlation-ID",
			"X-Request-ID",
			"X-RateLimit-Limit",
			"X-RateLimit-Remaining",
			"X-RateLimit-Reset",
		},
		AllowCredentials: true,
		MaxAge:           86400,
	}
}

// CORSMiddleware returns a Gin middleware for CORS.
func CORSMiddleware(cfg *CORSConfig) gin.HandlerFunc {
	if cfg == nil {
		cfg = DefaultCORSConfig()
	}

	allowMethods := strings.Join(cfg.AllowedMethods, ", ")
	allowHeaders := strings.Join(cfg.AllowedHeaders, ", ")
	exposeHeaders := strings.Join(cfg.ExposedHeaders, ", ")
	maxAge := strconv.Itoa(cfg.MaxAge)

	originMap := make(map[string]bool)
	allowAllOrigins := false
	for _, origin := range cfg.AllowedOrigins {
		if origin == "*" {
			allowAllOrigins = true
			break
		}
		originMap[origin] = true
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		if allowAllOrigins {
			c.Header("Access-Control-Allow-Origin", "*")
		} else if originMap[origin] {
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Vary", "Origin")
		} else if origin != "" {
			if c.Request.Method == http.MethodOptions {
				c.AbortWithStatus(http.StatusForbidden)
				return
			}
		}

		c.Header("Access-Control-Allow-Methods", allowMethods)
		c.Header("Access-Control-Allow-Headers", allowHeaders)
		c.Header("Access-Control-Expose-Headers", exposeHeaders)
		c.Header("Access-Control-Max-Age", maxAge)

		if cfg.AllowCredentials {
			c.Header("Access-Control-Allow-Credentials", "true")
		}

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// RateLimitConfig configures rate limiting.
type RateLimitConfig struct {
	Requests int
	Window   time.Duration
	KeyFunc  func(*gin.Context) string
}

// DefaultRateLimitConfig returns default rate limit configuration.
func DefaultRateLimitConfig() *RateLimitConfig {
	return &RateLimitConfig{
		Requests: 100,
		Window:   time.Minute,
		KeyFunc: func(c *gin.Context) string {
			return c.ClientIP()
		},
	}
}

type rateLimitEntry struct {
	count   int
	resetAt time.Time
}

// RateLimiter implements in-memory rate limiting.
type RateLimiter struct {
	config  *RateLimitConfig
	entries map[string]*rateLimitEntry
	mu      sync.RWMutex
}

// NewRateLimiter creates a new rate limiter.
func NewRateLimiter(cfg *RateLimitConfig) *RateLimiter {
	if cfg == nil {
		cfg = DefaultRateLimitConfig()
	}

	rl := &RateLimiter{
		config:  cfg,
		entries: make(map[string]*rateLimitEntry),
	}

	go rl.cleanup()

	return rl
}

func (rl *RateLimiter) cleanup() {
	ticker := time.NewTicker(rl.config.Window)
	defer ticker.Stop()

	for range ticker.C {
		rl.mu.Lock()
		now := time.Now()
		for key, entry := range rl.entries {
			if now.After(entry.resetAt) {
				delete(rl.entries, key)
			}
		}
		rl.mu.Unlock()
	}
}

// Allow checks if a request is allowed and increments the counter.
func (rl *RateLimiter) Allow(key string) (allowed bool, remaining int, resetAt time.Time) {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	entry, exists := rl.entries[key]

	if !exists || now.After(entry.resetAt) {
		entry = &rateLimitEntry{
			count:   1,
			resetAt: now.Add(rl.config.Window),
		}
		rl.entries[key] = entry
		return true, rl.config.Requests - 1, entry.resetAt
	}

	if entry.count >= rl.config.Requests {
		return false, 0, entry.resetAt
	}

	entry.count++
	return true, rl.config.Requests - entry.count, entry.resetAt
}

// RateLimitMiddleware returns a Gin middleware for rate limiting.
func RateLimitMiddleware(rl *RateLimiter) gin.HandlerFunc {
	return rl.GinMiddleware()
}

// GinMiddleware returns a Gin middleware handler for rate limiting.
func (rl *RateLimiter) GinMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		key := rl.config.KeyFunc(c)
		allowed, remaining, resetAt := rl.Allow(key)

		c.Header("X-RateLimit-Limit", strconv.Itoa(rl.config.Requests))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(resetAt.Unix(), 10))

		if !allowed {
			c.Header("Retry-After", strconv.FormatInt(int64(time.Until(resetAt).Seconds()), 10))
			TooManyRequests(c, "Rate limit exceeded")
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequestIDMiddleware adds a unique request ID to each request.
func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = uuid.NewString()
		}
		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)
		c.Next()
	}
}

// CorrelationIDMiddleware adds a correlation ID for distributed tracing.
func CorrelationIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		correlationID := c.GetHeader("X-Correlation-ID")
		if correlationID == "" {
			correlationID = uuid.NewString()
		}
		c.Set("correlation_id", correlationID)
		c.Header("X-Correlation-ID", correlationID)
		c.Next()
	}
}

// SecurityHeadersMiddleware adds security headers to responses.
func SecurityHeadersMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Header("Content-Security-Policy", "default-src 'self'")
		c.Next()
	}
}

// RequestSizeLimitMiddleware limits request body size.
func RequestSizeLimitMiddleware(maxBytes int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
		c.Next()
	}
}

// RecoveryMiddleware returns middleware for panic recovery.
func RecoveryMiddleware() gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		InternalServerError(c, "An unexpected error occurred")
	})
}

// NoRouteHandler returns a handler for 404 responses.
func NoRouteHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		NotFound(c, "The requested endpoint does not exist")
	}
}

// NoMethodHandler returns a handler for 405 responses.
func NoMethodHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		Error(c, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "The requested method is not allowed for this endpoint")
	}
}
