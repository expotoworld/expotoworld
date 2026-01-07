// Package database provides PostgreSQL database connectivity optimized for Neon serverless.
// It implements connection pooling with pgxpool and provides helper functions
// for common database operations.
package database

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Pool wraps pgxpool.Pool with additional functionality.
type Pool struct {
	*pgxpool.Pool
	logger *slog.Logger
}

// PoolConfig holds configuration for the database connection pool.
type PoolConfig struct {
	URL             string
	MaxConns        int32
	MinConns        int32
	MaxConnLifetime time.Duration
	MaxConnIdleTime time.Duration
	Logger          *slog.Logger
}

// DefaultPoolConfig returns sensible defaults for Neon serverless.
func DefaultPoolConfig(databaseURL string) *PoolConfig {
	return &PoolConfig{
		URL:             databaseURL,
		MaxConns:        10,
		MinConns:        2,
		MaxConnLifetime: 30 * time.Minute,
		MaxConnIdleTime: 5 * time.Minute,
	}
}

// NewPool creates a new database connection pool optimized for Neon serverless.
func NewPool(ctx context.Context, cfg *PoolConfig) (*Pool, error) {
	if cfg.URL == "" {
		return nil, errors.New("database URL is required")
	}

	logger := cfg.Logger
	if logger == nil {
		logger = slog.Default()
	}

	poolConfig, err := pgxpool.ParseConfig(cfg.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database URL: %w", err)
	}

	// Apply pool settings
	poolConfig.MaxConns = cfg.MaxConns
	poolConfig.MinConns = cfg.MinConns
	poolConfig.MaxConnLifetime = cfg.MaxConnLifetime
	poolConfig.MaxConnIdleTime = cfg.MaxConnIdleTime

	// Neon-specific optimizations
	configureForNeon(poolConfig)

	// Configure connection hooks for logging
	poolConfig.BeforeAcquire = func(ctx context.Context, conn *pgx.Conn) bool {
		logger.Debug("acquiring database connection",
			slog.String("remote_addr", conn.PgConn().Conn().RemoteAddr().String()),
		)
		return true
	}

	poolConfig.AfterRelease = func(conn *pgx.Conn) bool {
		logger.Debug("releasing database connection")
		return true
	}

	// Create the pool
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	// Verify connectivity
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	logger.Info("database connection pool established",
		slog.Int("max_conns", int(cfg.MaxConns)),
		slog.Int("min_conns", int(cfg.MinConns)),
	)

	return &Pool{Pool: pool, logger: logger}, nil
}

// configureForNeon applies Neon-specific connection settings.
func configureForNeon(cfg *pgxpool.Config) {
	// Use simple protocol for better compatibility with Neon's connection pooler
	cfg.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol

	// Prefer IPv4 to avoid IPv6 connection issues
	cfg.ConnConfig.DialFunc = func(ctx context.Context, network, addr string) (net.Conn, error) {
		d := &net.Dialer{
			Timeout:   10 * time.Second,
			KeepAlive: 30 * time.Second,
		}
		// Try IPv4 first
		conn, err := d.DialContext(ctx, "tcp4", addr)
		if err == nil {
			return conn, nil
		}
		// Fallback to any available network
		return d.DialContext(ctx, network, addr)
	}

	// Configure timeouts
	cfg.ConnConfig.ConnectTimeout = 15 * time.Second
}

// Stats returns pool statistics.
func (p *Pool) Stats() PoolStats {
	s := p.Pool.Stat()
	return PoolStats{
		AcquireCount:         s.AcquireCount(),
		AcquireDuration:      s.AcquireDuration(),
		AcquiredConns:        s.AcquiredConns(),
		CanceledAcquireCount: s.CanceledAcquireCount(),
		ConstructingConns:    s.ConstructingConns(),
		EmptyAcquireCount:    s.EmptyAcquireCount(),
		IdleConns:            s.IdleConns(),
		MaxConns:             s.MaxConns(),
		TotalConns:           s.TotalConns(),
	}
}

// PoolStats holds connection pool statistics.
type PoolStats struct {
	AcquireCount         int64
	AcquireDuration      time.Duration
	AcquiredConns        int32
	CanceledAcquireCount int64
	ConstructingConns    int32
	EmptyAcquireCount    int64
	IdleConns            int32
	MaxConns             int32
	TotalConns           int32
}

// HealthCheck performs a database health check.
func (p *Pool) HealthCheck(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	var result int
	err := p.QueryRow(ctx, "SELECT 1").Scan(&result)
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	return nil
}

// WithTx executes a function within a database transaction.
// The transaction is automatically committed on success or rolled back on error.
func (p *Pool) WithTx(ctx context.Context, opts pgx.TxOptions, fn func(tx pgx.Tx) error) error {
	tx, err := p.BeginTx(ctx, opts)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	defer func() {
		if r := recover(); r != nil {
			_ = tx.Rollback(ctx)
			panic(r)
		}
	}()

	if err := fn(tx); err != nil {
		if rbErr := tx.Rollback(ctx); rbErr != nil {
			p.logger.Error("failed to rollback transaction",
				slog.String("error", rbErr.Error()),
			)
		}
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// ErrNoRows checks if an error is pgx.ErrNoRows.
func ErrNoRows(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}

// IsUniqueViolation checks if an error is a unique constraint violation.
func IsUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23505"
	}
	return false
}

// IsForeignKeyViolation checks if an error is a foreign key constraint violation.
func IsForeignKeyViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23503"
	}
	return false
}

// IsCheckViolation checks if an error is a check constraint violation.
func IsCheckViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23514"
	}
	return false
}

// IsNotNullViolation checks if an error is a NOT NULL constraint violation.
func IsNotNullViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23502"
	}
	return false
}

// GetConstraintName extracts the constraint name from a PostgreSQL error.
func GetConstraintName(err error) string {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.ConstraintName
	}
	return ""
}

// Batch provides a wrapper for pgx.Batch operations.
type Batch struct {
	batch *pgx.Batch
}

// NewBatch creates a new batch operation.
func NewBatch() *Batch {
	return &Batch{batch: &pgx.Batch{}}
}

// Queue adds a query to the batch.
func (b *Batch) Queue(query string, args ...interface{}) {
	b.batch.Queue(query, args...)
}

// Len returns the number of queued queries.
func (b *Batch) Len() int {
	return b.batch.Len()
}

// SendBatch sends a batch of queries to the database.
func (p *Pool) SendBatch(ctx context.Context, b *Batch) pgx.BatchResults {
	return p.Pool.SendBatch(ctx, b.batch)
}

// Pagination represents pagination parameters.
type Pagination struct {
	Limit  int
	Offset int
}

// NewPagination creates pagination from page and pageSize.
func NewPagination(page, pageSize int) Pagination {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}
	return Pagination{
		Limit:  pageSize,
		Offset: (page - 1) * pageSize,
	}
}

// PaginatedResult represents a paginated query result.
type PaginatedResult[T any] struct {
	Items      []T   `json:"items"`
	Page       int   `json:"page"`
	PageSize   int   `json:"page_size"`
	TotalCount int64 `json:"total_count"`
	TotalPages int   `json:"total_pages"`
}

// NewPaginatedResult creates a new paginated result.
func NewPaginatedResult[T any](items []T, page, pageSize int, totalCount int64) PaginatedResult[T] {
	totalPages := int(totalCount) / pageSize
	if int(totalCount)%pageSize > 0 {
		totalPages++
	}
	return PaginatedResult[T]{
		Items:      items,
		Page:       page,
		PageSize:   pageSize,
		TotalCount: totalCount,
		TotalPages: totalPages,
	}
}

// SortOrder represents a sorting order.
type SortOrder string

const (
	SortAsc  SortOrder = "ASC"
	SortDesc SortOrder = "DESC"
)

// Sort represents a sorting configuration.
type Sort struct {
	Field string
	Order SortOrder
}

// NewSort creates a new sort configuration with validation.
func NewSort(field string, order SortOrder, allowedFields []string) Sort {
	// Default to created_at DESC if invalid
	validField := false
	for _, allowed := range allowedFields {
		if field == allowed {
			validField = true
			break
		}
	}

	if !validField {
		field = "created_at"
	}

	if order != SortAsc && order != SortDesc {
		order = SortDesc
	}

	return Sort{Field: field, Order: order}
}

// String returns the SQL ORDER BY clause.
func (s Sort) String() string {
	return fmt.Sprintf("%s %s", s.Field, s.Order)
}
