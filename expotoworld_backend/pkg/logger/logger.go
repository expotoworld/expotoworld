// Package logger provides structured logging using Go's slog package.
// It supports JSON and text output formats with configurable log levels.
package logger

import (
	"context"
	"io"
	"log/slog"
	"os"
	"runtime"
	"strings"
	"time"
)

// Logger wraps slog.Logger with additional functionality.
type Logger struct {
	*slog.Logger
}

// Config holds logger configuration.
type Config struct {
	Level       string // debug, info, warn, error
	Format      string // text, json
	Output      io.Writer
	ServiceName string
	Environment string
	AddSource   bool
}

// DefaultConfig returns sensible defaults for development.
func DefaultConfig() Config {
	return Config{
		Level:     "debug",
		Format:    "text",
		Output:    os.Stdout,
		AddSource: false,
	}
}

// New creates a new Logger with the given configuration.
func New(cfg Config) *Logger {
	level := parseLevel(cfg.Level)

	output := cfg.Output
	if output == nil {
		output = os.Stdout
	}

	opts := &slog.HandlerOptions{
		Level:     level,
		AddSource: cfg.AddSource,
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			// Customize time format
			if a.Key == slog.TimeKey {
				a.Value = slog.StringValue(a.Value.Time().Format(time.RFC3339))
			}
			return a
		},
	}

	var handler slog.Handler
	if strings.ToLower(cfg.Format) == "json" {
		handler = slog.NewJSONHandler(output, opts)
	} else {
		handler = slog.NewTextHandler(output, opts)
	}

	// Add default attributes
	if cfg.ServiceName != "" {
		handler = handler.WithAttrs([]slog.Attr{
			slog.String("service", cfg.ServiceName),
		})
	}
	if cfg.Environment != "" {
		handler = handler.WithAttrs([]slog.Attr{
			slog.String("env", cfg.Environment),
		})
	}

	return &Logger{Logger: slog.New(handler)}
}

// parseLevel converts a string level to slog.Level.
func parseLevel(level string) slog.Level {
	switch strings.ToLower(level) {
	case "debug":
		return slog.LevelDebug
	case "info":
		return slog.LevelInfo
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

// SetDefault sets the default logger for the application.
func SetDefault(l *Logger) {
	slog.SetDefault(l.Logger)
}

// Default returns the default logger.
func Default() *Logger {
	return &Logger{Logger: slog.Default()}
}

// With returns a new Logger with additional attributes.
func (l *Logger) With(args ...any) *Logger {
	return &Logger{Logger: l.Logger.With(args...)}
}

// WithGroup returns a new Logger with the given group name.
func (l *Logger) WithGroup(name string) *Logger {
	return &Logger{Logger: l.Logger.WithGroup(name)}
}

// WithContext returns a new Logger with context values extracted.
func (l *Logger) WithContext(ctx context.Context) *Logger {
	attrs := []any{}

	// Extract correlation ID if present
	if corrID := GetCorrelationID(ctx); corrID != "" {
		attrs = append(attrs, slog.String("correlation_id", corrID))
	}

	// Extract user ID if present
	if userID := GetUserID(ctx); userID != "" {
		attrs = append(attrs, slog.String("user_id", userID))
	}

	// Extract request ID if present
	if reqID := GetRequestID(ctx); reqID != "" {
		attrs = append(attrs, slog.String("request_id", reqID))
	}

	if len(attrs) > 0 {
		return l.With(attrs...)
	}
	return l
}

// WithError returns a new Logger with error information.
func (l *Logger) WithError(err error) *Logger {
	if err == nil {
		return l
	}
	return l.With(slog.String("error", err.Error()))
}

// WithCaller returns a new Logger with caller information.
func (l *Logger) WithCaller(skip int) *Logger {
	_, file, line, ok := runtime.Caller(skip + 1)
	if !ok {
		return l
	}
	return l.With(
		slog.String("file", file),
		slog.Int("line", line),
	)
}

// DebugContext logs at debug level with context.
func (l *Logger) DebugContext(ctx context.Context, msg string, args ...any) {
	l.WithContext(ctx).Debug(msg, args...)
}

// InfoContext logs at info level with context.
func (l *Logger) InfoContext(ctx context.Context, msg string, args ...any) {
	l.WithContext(ctx).Info(msg, args...)
}

// WarnContext logs at warn level with context.
func (l *Logger) WarnContext(ctx context.Context, msg string, args ...any) {
	l.WithContext(ctx).Warn(msg, args...)
}

// ErrorContext logs at error level with context.
func (l *Logger) ErrorContext(ctx context.Context, msg string, args ...any) {
	l.WithContext(ctx).Error(msg, args...)
}

// Context keys for logging
type contextKey string

const (
	correlationIDKey contextKey = "correlation_id"
	userIDKey        contextKey = "user_id"
	requestIDKey     contextKey = "request_id"
)

// WithCorrelationID adds a correlation ID to the context.
func WithCorrelationID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, correlationIDKey, id)
}

// GetCorrelationID extracts the correlation ID from context.
func GetCorrelationID(ctx context.Context) string {
	if id, ok := ctx.Value(correlationIDKey).(string); ok {
		return id
	}
	return ""
}

// WithUserID adds a user ID to the context.
func WithUserID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, userIDKey, id)
}

// GetUserID extracts the user ID from context.
func GetUserID(ctx context.Context) string {
	if id, ok := ctx.Value(userIDKey).(string); ok {
		return id
	}
	return ""
}

// WithRequestID adds a request ID to the context.
func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestIDKey, id)
}

// GetRequestID extracts the request ID from context.
func GetRequestID(ctx context.Context) string {
	if id, ok := ctx.Value(requestIDKey).(string); ok {
		return id
	}
	return ""
}

// HTTP request logging helpers

// HTTPRequestInfo holds HTTP request information for logging.
type HTTPRequestInfo struct {
	Method       string
	Path         string
	Query        string
	ClientIP     string
	UserAgent    string
	Latency      time.Duration
	StatusCode   int
	BodySize     int
	RequestID    string
	ErrorMessage string
}

// LogHTTPRequest logs an HTTP request with common fields.
func (l *Logger) LogHTTPRequest(ctx context.Context, info HTTPRequestInfo) {
	attrs := []any{
		slog.String("method", info.Method),
		slog.String("path", info.Path),
		slog.String("client_ip", info.ClientIP),
		slog.Int("status", info.StatusCode),
		slog.Duration("latency", info.Latency),
		slog.Int("body_size", info.BodySize),
	}

	if info.Query != "" {
		attrs = append(attrs, slog.String("query", info.Query))
	}
	if info.UserAgent != "" {
		attrs = append(attrs, slog.String("user_agent", info.UserAgent))
	}
	if info.RequestID != "" {
		attrs = append(attrs, slog.String("request_id", info.RequestID))
	}
	if info.ErrorMessage != "" {
		attrs = append(attrs, slog.String("error", info.ErrorMessage))
	}

	// Determine log level based on status code
	switch {
	case info.StatusCode >= 500:
		l.WithContext(ctx).Error("HTTP request completed", attrs...)
	case info.StatusCode >= 400:
		l.WithContext(ctx).Warn("HTTP request completed", attrs...)
	default:
		l.WithContext(ctx).Info("HTTP request completed", attrs...)
	}
}

// LogDatabaseQuery logs a database query for debugging.
func (l *Logger) LogDatabaseQuery(ctx context.Context, query string, duration time.Duration, err error) {
	attrs := []any{
		slog.String("query", truncateQuery(query, 500)),
		slog.Duration("duration", duration),
	}

	if err != nil {
		attrs = append(attrs, slog.String("error", err.Error()))
		l.WithContext(ctx).Error("database query failed", attrs...)
	} else {
		l.WithContext(ctx).Debug("database query executed", attrs...)
	}
}

// truncateQuery truncates a query string to a maximum length.
func truncateQuery(query string, maxLen int) string {
	if len(query) <= maxLen {
		return query
	}
	return query[:maxLen] + "..."
}

// Structured logging fields

// String creates a string field.
func String(key, value string) slog.Attr {
	return slog.String(key, value)
}

// Int creates an int field.
func Int(key string, value int) slog.Attr {
	return slog.Int(key, value)
}

// Int64 creates an int64 field.
func Int64(key string, value int64) slog.Attr {
	return slog.Int64(key, value)
}

// Float64 creates a float64 field.
func Float64(key string, value float64) slog.Attr {
	return slog.Float64(key, value)
}

// Bool creates a bool field.
func Bool(key string, value bool) slog.Attr {
	return slog.Bool(key, value)
}

// Duration creates a duration field.
func Duration(key string, value time.Duration) slog.Attr {
	return slog.Duration(key, value)
}

// Time creates a time field.
func Time(key string, value time.Time) slog.Attr {
	return slog.Time(key, value)
}

// Any creates a field for any value.
func Any(key string, value any) slog.Attr {
	return slog.Any(key, value)
}

// Error creates an error field.
func Error(err error) slog.Attr {
	if err == nil {
		return slog.Attr{}
	}
	return slog.String("error", err.Error())
}

// Group creates a group of attributes.
func Group(key string, attrs ...any) slog.Attr {
	return slog.Group(key, attrs...)
}
