// Package postgres provides PostgreSQL implementations of repositories.
// This implementation is adapted for the legacy single-ebook database schema
// where ebook_media_usage uses only media_key as the primary key (no ebook_id).
package postgres

import (
	"context"
	"fmt"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/repository"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// MediaUsageRepository implements repository.MediaUsageRepository using PostgreSQL.
// Adapted for legacy schema where media_key is the only key (single ebook design).
type MediaUsageRepository struct {
	pool *pgxpool.Pool
}

// NewMediaUsageRepository creates a new MediaUsageRepository.
func NewMediaUsageRepository(pool *pgxpool.Pool) *MediaUsageRepository {
	return &MediaUsageRepository{pool: pool}
}

// Get returns media usage for the given media key.
// Note: ebookID parameter is ignored in legacy schema (single ebook design).
func (r *MediaUsageRepository) Get(ctx context.Context, ebookID, mediaKey string) (*domain.MediaUsage, error) {
	var usage domain.MediaUsage
	err := r.pool.QueryRow(ctx,
		`SELECT media_key, in_autosave, manual_refs, published_refs, last_seen_at
		 FROM ebook_media_usage WHERE media_key = $1`,
		mediaKey).Scan(
		&usage.MediaKey, &usage.InAutosave, &usage.ManualRefs, &usage.PublishedRefs, &usage.LastSeenAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("query media usage: %w", err)
	}
	return &usage, nil
}

// UpsertAutosave marks a media key as used in autosave.
// Note: ebookID parameter is ignored in legacy schema (single ebook design).
func (r *MediaUsageRepository) UpsertAutosave(ctx context.Context, ebookID, mediaKey string, inAutosave bool) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_media_usage (media_key, in_autosave, last_seen_at)
		 VALUES ($1, $2, now())
		 ON CONFLICT (media_key) DO UPDATE SET in_autosave = $2, last_seen_at = now()`,
		mediaKey, inAutosave)
	if err != nil {
		return fmt.Errorf("upsert autosave: %w", err)
	}
	return nil
}

// IncrementManualRefs increments the manual reference count.
func (r *MediaUsageRepository) IncrementManualRefs(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebook_media_usage SET manual_refs = manual_refs + 1 
		 WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("increment manual refs: %w", err)
	}
	return nil
}

// DecrementManualRefs decrements the manual reference count.
func (r *MediaUsageRepository) DecrementManualRefs(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebook_media_usage SET manual_refs = GREATEST(manual_refs - 1, 0) 
		 WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("decrement manual refs: %w", err)
	}
	return nil
}

// IncrementPublishedRefs increments the published reference count.
func (r *MediaUsageRepository) IncrementPublishedRefs(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebook_media_usage SET published_refs = published_refs + 1 
		 WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("increment published refs: %w", err)
	}
	return nil
}

// DecrementPublishedRefs decrements the published reference count.
func (r *MediaUsageRepository) DecrementPublishedRefs(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebook_media_usage SET published_refs = GREATEST(published_refs - 1, 0) 
		 WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("decrement published refs: %w", err)
	}
	return nil
}

// UpdateLastSeen updates the last seen timestamp.
func (r *MediaUsageRepository) UpdateLastSeen(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebook_media_usage SET last_seen_at = now() WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("update last seen: %w", err)
	}
	return nil
}

// ResetAll resets all autosave flags for all media.
// Note: In legacy schema, this resets ALL media since there's only one ebook.
func (r *MediaUsageRepository) ResetAll(ctx context.Context, ebookID string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE ebook_media_usage SET in_autosave = false`)
	if err != nil {
		return fmt.Errorf("reset all: %w", err)
	}
	return nil
}

// UpsertPublished marks a media key as used in published version.
// Note: Legacy schema doesn't have in_published column, using manual_refs instead.
func (r *MediaUsageRepository) UpsertPublished(ctx context.Context, ebookID, mediaKey string, inPublished bool) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_media_usage (media_key, in_autosave, last_seen_at)
		 VALUES ($1, false, now())
		 ON CONFLICT (media_key) DO UPDATE SET last_seen_at = now()`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("upsert published: %w", err)
	}
	return nil
}

// Delete removes a media usage entry.
func (r *MediaUsageRepository) Delete(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.pool.Exec(ctx,
		`DELETE FROM ebook_media_usage WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("delete media usage: %w", err)
	}
	return nil
}

// DeleteByEbook removes all media usage entries.
// Note: In legacy schema, this removes ALL media since there's only one ebook.
func (r *MediaUsageRepository) DeleteByEbook(ctx context.Context, ebookID string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM ebook_media_usage`)
	if err != nil {
		return fmt.Errorf("delete all media usage: %w", err)
	}
	return nil
}

// WithTx returns a transaction-scoped repository.
func (r *MediaUsageRepository) WithTx(tx pgx.Tx) repository.TxMediaUsageRepository {
	return NewTxMediaUsageRepository(tx)
}

// TxMediaUsageRepository wraps MediaUsageRepository for transaction operations.
type TxMediaUsageRepository struct {
	tx pgx.Tx
}

// NewTxMediaUsageRepository creates a new TxMediaUsageRepository.
func NewTxMediaUsageRepository(tx pgx.Tx) *TxMediaUsageRepository {
	return &TxMediaUsageRepository{tx: tx}
}

// IncrementManualRefs increments the manual reference count within a transaction.
func (r *TxMediaUsageRepository) IncrementManualRefs(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.tx.Exec(ctx,
		`UPDATE ebook_media_usage SET manual_refs = manual_refs + 1 
		 WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("increment manual refs: %w", err)
	}
	return nil
}

// DecrementManualRefs decrements the manual reference count within a transaction.
func (r *TxMediaUsageRepository) DecrementManualRefs(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.tx.Exec(ctx,
		`UPDATE ebook_media_usage SET manual_refs = GREATEST(manual_refs - 1, 0) 
		 WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("decrement manual refs: %w", err)
	}
	return nil
}

// IncrementPublishedRefs increments the published reference count within a transaction.
func (r *TxMediaUsageRepository) IncrementPublishedRefs(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.tx.Exec(ctx,
		`UPDATE ebook_media_usage SET published_refs = published_refs + 1 
		 WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("increment published refs: %w", err)
	}
	return nil
}

// DecrementPublishedRefs decrements the published reference count within a transaction.
func (r *TxMediaUsageRepository) DecrementPublishedRefs(ctx context.Context, ebookID, mediaKey string) error {
	_, err := r.tx.Exec(ctx,
		`UPDATE ebook_media_usage SET published_refs = GREATEST(published_refs - 1, 0) 
		 WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("decrement published refs: %w", err)
	}
	return nil
}

// UpsertPublished marks a media key as used in published version within a transaction.
func (r *TxMediaUsageRepository) UpsertPublished(ctx context.Context, ebookID, mediaKey string, inPublished bool) error {
	_, err := r.tx.Exec(ctx,
		`INSERT INTO ebook_media_usage (media_key, in_autosave, last_seen_at)
		 VALUES ($1, false, now())
		 ON CONFLICT (media_key) DO UPDATE SET last_seen_at = now()`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("upsert published: %w", err)
	}
	return nil
}
