package postgres

import (
	"context"
	"fmt"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/repository"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// VersionRepository implements repository.VersionRepository using PostgreSQL.
type VersionRepository struct {
	pool *pgxpool.Pool
}

// NewVersionRepository creates a new VersionRepository.
func NewVersionRepository(pool *pgxpool.Pool) *VersionRepository {
	return &VersionRepository{pool: pool}
}

// GetByID returns a version by ID.
func (r *VersionRepository) GetByID(ctx context.Context, id string) (*domain.Version, error) {
	var version domain.Version
	var label *string
	err := r.pool.QueryRow(ctx,
		`SELECT id, ebook_id, kind, label, s3_key, created_at
		 FROM ebook_versions WHERE id = $1`, id).Scan(
		&version.ID, &version.EbookID, &version.Kind, &label, &version.S3Key,
		&version.CreatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, domain.ErrVersionNotFound
		}
		return nil, fmt.Errorf("query version: %w", err)
	}
	if label != nil {
		version.Label = *label
	}
	return &version, nil
}

// ListByEbook returns all versions for an ebook.
func (r *VersionRepository) ListByEbook(ctx context.Context, ebookID string) ([]*domain.Version, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, ebook_id, kind, label, s3_key, created_at
		 FROM ebook_versions WHERE ebook_id = $1 ORDER BY created_at DESC`, ebookID)
	if err != nil {
		return nil, fmt.Errorf("query versions: %w", err)
	}
	defer rows.Close()

	var versions []*domain.Version
	for rows.Next() {
		var v domain.Version
		var label *string
		if err := rows.Scan(&v.ID, &v.EbookID, &v.Kind, &label, &v.S3Key,
			&v.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan version: %w", err)
		}
		if label != nil {
			v.Label = *label
		}
		versions = append(versions, &v)
	}
	if versions == nil {
		versions = []*domain.Version{}
	}
	return versions, nil
}

// Create creates a new version.
func (r *VersionRepository) Create(ctx context.Context, version *domain.Version) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_versions (id, ebook_id, kind, label, s3_key, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6)`,
		version.ID, version.EbookID, version.Kind, version.Label, version.S3Key,
		version.CreatedAt)
	if err != nil {
		return fmt.Errorf("create version: %w", err)
	}
	return nil
}

// Update updates a version.
func (r *VersionRepository) Update(ctx context.Context, version *domain.Version) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebook_versions SET label = $1 WHERE id = $2`,
		version.Label, version.ID)
	if err != nil {
		return fmt.Errorf("update version: %w", err)
	}
	return nil
}

// Delete deletes a version by ID.
func (r *VersionRepository) Delete(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM ebook_versions WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("delete version: %w", err)
	}
	return nil
}

// ListByEbookID returns all versions for an ebook (alias for ListByEbook).
func (r *VersionRepository) ListByEbookID(ctx context.Context, ebookID string) ([]*domain.Version, error) {
	return r.ListByEbook(ctx, ebookID)
}

// UpdateKind updates only the kind field of a version.
func (r *VersionRepository) UpdateKind(ctx context.Context, id string, kind domain.VersionKind) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebook_versions SET kind = $1 WHERE id = $2`, kind, id)
	if err != nil {
		return fmt.Errorf("update version kind: %w", err)
	}
	return nil
}

// WithTx returns a transaction-scoped repository.
func (r *VersionRepository) WithTx(tx pgx.Tx) repository.TxVersionRepository {
	return NewTxVersionRepository(tx)
}

// TxVersionRepository wraps VersionRepository for transaction operations.
type TxVersionRepository struct {
	tx pgx.Tx
}

// NewTxVersionRepository creates a new TxVersionRepository.
func NewTxVersionRepository(tx pgx.Tx) *TxVersionRepository {
	return &TxVersionRepository{tx: tx}
}

// GetByID returns a version by ID within a transaction.
func (r *TxVersionRepository) GetByID(ctx context.Context, id string) (*domain.Version, error) {
	var version domain.Version
	var label *string
	err := r.tx.QueryRow(ctx,
		`SELECT id, ebook_id, kind, label, s3_key, created_at
		 FROM ebook_versions WHERE id = $1`, id).Scan(
		&version.ID, &version.EbookID, &version.Kind, &label, &version.S3Key,
		&version.CreatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, domain.ErrVersionNotFound
		}
		return nil, fmt.Errorf("query version: %w", err)
	}
	if label != nil {
		version.Label = *label
	}
	return &version, nil
}

// Create creates a new version within a transaction.
func (r *TxVersionRepository) Create(ctx context.Context, version *domain.Version) error {
	_, err := r.tx.Exec(ctx,
		`INSERT INTO ebook_versions (id, ebook_id, kind, label, s3_key, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6)`,
		version.ID, version.EbookID, version.Kind, version.Label, version.S3Key,
		version.CreatedAt)
	if err != nil {
		return fmt.Errorf("create version: %w", err)
	}
	return nil
}

// Update updates a version within a transaction.
func (r *TxVersionRepository) Update(ctx context.Context, version *domain.Version) error {
	_, err := r.tx.Exec(ctx,
		`UPDATE ebook_versions SET label = $1 WHERE id = $2`,
		version.Label, version.ID)
	if err != nil {
		return fmt.Errorf("update version: %w", err)
	}
	return nil
}

// Delete deletes a version within a transaction.
func (r *TxVersionRepository) Delete(ctx context.Context, id string) error {
	_, err := r.tx.Exec(ctx, `DELETE FROM ebook_versions WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("delete version: %w", err)
	}
	return nil
}

// UpdateKind updates only the kind field of a version within a transaction.
func (r *TxVersionRepository) UpdateKind(ctx context.Context, id string, kind domain.VersionKind) error {
	_, err := r.tx.Exec(ctx,
		`UPDATE ebook_versions SET kind = $1 WHERE id = $2`, kind, id)
	if err != nil {
		return fmt.Errorf("update version kind: %w", err)
	}
	return nil
}
