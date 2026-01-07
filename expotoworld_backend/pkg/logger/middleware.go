package logger

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GinMiddleware returns a Gin middleware for request logging.
func GinMiddleware(l *Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		// Get or generate request ID
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = uuid.NewString()
		}
		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)

		// Get or generate correlation ID
		correlationID := c.GetHeader("X-Correlation-ID")
		if correlationID == "" {
			correlationID = uuid.NewString()
		}
		c.Set("correlation_id", correlationID)
		c.Header("X-Correlation-ID", correlationID)

		// Add IDs to context
		ctx := WithRequestID(c.Request.Context(), requestID)
		ctx = WithCorrelationID(ctx, correlationID)
		c.Request = c.Request.WithContext(ctx)

		// Process request
		c.Next()

		// Calculate latency
		latency := time.Since(start)

		// Get error message if any
		var errorMsg string
		if len(c.Errors) > 0 {
			errorMsg = c.Errors.String()
		}

		// Log the request
		l.LogHTTPRequest(ctx, HTTPRequestInfo{
			Method:       c.Request.Method,
			Path:         c.Request.URL.Path,
			Query:        c.Request.URL.RawQuery,
			ClientIP:     c.ClientIP(),
			UserAgent:    c.Request.UserAgent(),
			Latency:      latency,
			StatusCode:   c.Writer.Status(),
			BodySize:     c.Writer.Size(),
			RequestID:    requestID,
			ErrorMessage: errorMsg,
		})
	}
}

// RecoveryMiddleware returns middleware that logs panics.
func RecoveryMiddleware(l *Logger) gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		requestID := c.GetString("request_id")

		l.WithContext(c.Request.Context()).Error("panic recovered",
			String("request_id", requestID),
			String("path", c.Request.URL.Path),
			String("method", c.Request.Method),
			Any("panic", recovered),
		)

		c.AbortWithStatusJSON(500, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "An internal error occurred",
			},
		})
	})
}

// ContextLogger returns a logger with context values.
func ContextLogger(c *gin.Context, l *Logger) *Logger {
	return l.WithContext(c.Request.Context())
}
