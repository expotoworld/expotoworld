// Package postgres provides PostgreSQL implementations of repositories.
package postgres

import (
	"context"
	"fmt"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/repository"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// EbookRepository implements repository.EbookRepository using PostgreSQL.
type EbookRepository struct {
	pool *pgxpool.Pool
}

// NewEbookRepository creates a new EbookRepository.
func NewEbookRepository(pool *pgxpool.Pool) *EbookRepository {
	return &EbookRepository{pool: pool}
}

// GetByID returns the ebook by UUID.
func (r *EbookRepository) GetByID(ctx context.Context, id string) (*domain.Ebook, error) {
	var ebook domain.Ebook
	err := r.pool.QueryRow(ctx,
		`SELECT id, slug, title, content, created_at, updated_at 
		 FROM ebooks WHERE id = $1`, id).Scan(
		&ebook.ID, &ebook.Slug, &ebook.Title, &ebook.Content, &ebook.CreatedAt, &ebook.UpdatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, domain.ErrEbookNotFound
		}
		return nil, fmt.Errorf("query ebook by id: %w", err)
	}
	return &ebook, nil
}

// GetBySlug returns the ebook by slug.
func (r *EbookRepository) GetBySlug(ctx context.Context, slug string) (*domain.Ebook, error) {
	var ebook domain.Ebook
	err := r.pool.QueryRow(ctx,
		`SELECT id, slug, title, content, created_at, updated_at 
		 FROM ebooks WHERE slug = $1`, slug).Scan(
		&ebook.ID, &ebook.Slug, &ebook.Title, &ebook.Content, &ebook.CreatedAt, &ebook.UpdatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, domain.ErrEbookNotFound
		}
		return nil, fmt.Errorf("query ebook by slug: %w", err)
	}
	return &ebook, nil
}

// Create creates a new ebook and returns the generated ID.
func (r *EbookRepository) Create(ctx context.Context, ebook *domain.Ebook) error {
	// Let the database generate the UUID and timestamps
	err := r.pool.QueryRow(ctx,
		`INSERT INTO ebooks (slug, title, content) 
		 VALUES ($1, $2, $3)
		 RETURNING id, created_at, updated_at`,
		ebook.Slug, ebook.Title, ebook.Content).Scan(&ebook.ID, &ebook.CreatedAt, &ebook.UpdatedAt)
	if err != nil {
		return fmt.Errorf("create ebook: %w", err)
	}
	return nil
}

// UpdateContent updates the ebook's content.
func (r *EbookRepository) UpdateContent(ctx context.Context, slug string, content []byte) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebooks SET content = $1::jsonb, updated_at = now() WHERE slug = $2`,
		string(content), slug)
	if err != nil {
		return fmt.Errorf("update content: %w", err)
	}
	return nil
}

// UpdateTimestamp updates the ebook's updated_at timestamp.
func (r *EbookRepository) UpdateTimestamp(ctx context.Context, slug string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebooks SET updated_at = now() WHERE slug = $1`, slug)
	if err != nil {
		return fmt.Errorf("update timestamp: %w", err)
	}
	return nil
}

// WithTx returns a transaction-scoped repository.
func (r *EbookRepository) WithTx(tx pgx.Tx) repository.TxEbookRepository {
	return NewTxEbookRepository(tx)
}

// TxEbookRepository wraps EbookRepository for transaction operations.
type TxEbookRepository struct {
	tx pgx.Tx
}

// NewTxEbookRepository creates a new TxEbookRepository.
func NewTxEbookRepository(tx pgx.Tx) *TxEbookRepository {
	return &TxEbookRepository{tx: tx}
}

// GetByID returns the ebook by ID within a transaction.
func (r *TxEbookRepository) GetByID(ctx context.Context, id string) (*domain.Ebook, error) {
	var ebook domain.Ebook
	err := r.tx.QueryRow(ctx,
		`SELECT id, slug, title, content, created_at, updated_at 
		 FROM ebooks WHERE id = $1`, id).Scan(
		&ebook.ID, &ebook.Slug, &ebook.Title, &ebook.Content, &ebook.CreatedAt, &ebook.UpdatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, domain.ErrEbookNotFound
		}
		return nil, fmt.Errorf("query ebook: %w", err)
	}
	return &ebook, nil
}

// GetBySlug returns the ebook by slug within a transaction.
func (r *TxEbookRepository) GetBySlug(ctx context.Context, slug string) (*domain.Ebook, error) {
	var ebook domain.Ebook
	err := r.tx.QueryRow(ctx,
		`SELECT id, slug, title, content, created_at, updated_at 
		 FROM ebooks WHERE slug = $1`, slug).Scan(
		&ebook.ID, &ebook.Slug, &ebook.Title, &ebook.Content, &ebook.CreatedAt, &ebook.UpdatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, domain.ErrEbookNotFound
		}
		return nil, fmt.Errorf("query ebook by slug: %w", err)
	}
	return &ebook, nil
}

// UpdateContent updates the ebook's content within a transaction.
func (r *TxEbookRepository) UpdateContent(ctx context.Context, slug string, content []byte) error {
	_, err := r.tx.Exec(ctx,
		`UPDATE ebooks SET content = $1::jsonb, updated_at = now() WHERE slug = $2`,
		string(content), slug)
	if err != nil {
		return fmt.Errorf("update content: %w", err)
	}
	return nil
}
