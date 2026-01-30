package postgres

import (
	"context"
	"fmt"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/repository"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// MediaPendingRepository implements repository.MediaPendingRepository using PostgreSQL.
type MediaPendingRepository struct {
	pool *pgxpool.Pool
}

// NewMediaPendingRepository creates a new MediaPendingRepository.
func NewMediaPendingRepository(pool *pgxpool.Pool) *MediaPendingRepository {
	return &MediaPendingRepository{pool: pool}
}

// Schedule schedules a media key for deletion.
func (r *MediaPendingRepository) Schedule(ctx context.Context, mediaKey string, ttlMinutes int) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_media_pending_deletion (media_key, requested_at, not_before, attempts)
		 VALUES ($1, now(), now() + ($2::int * interval '1 minute'), 0)
		 ON CONFLICT (media_key) DO UPDATE SET requested_at = now(), not_before = now() + ($2::int * interval '1 minute')`,
		mediaKey, ttlMinutes)
	if err != nil {
		return fmt.Errorf("schedule deletion: %w", err)
	}
	return nil
}

// Create creates a pending deletion record.
func (r *MediaPendingRepository) Create(ctx context.Context, pending *domain.MediaPending) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_media_pending_deletion (media_key, requested_at, not_before, attempts)
		 VALUES ($1, $2, $3, 0)
		 ON CONFLICT (media_key) DO UPDATE SET requested_at = EXCLUDED.requested_at`,
		pending.S3Key, pending.MarkedAt, pending.MarkedAt)
	if err != nil {
		return fmt.Errorf("create pending deletion: %w", err)
	}
	return nil
}

// ListByEbook returns pending deletions for an ebook.
// Filters by media_key prefix: ebooks/{ebookID}/
func (r *MediaPendingRepository) ListByEbook(ctx context.Context, ebookID string) ([]*domain.MediaPendingDeletion, error) {
	// Media keys follow pattern: ebooks/{ebook_id}/media/{type}/{filename}
	// or: ebooks/{ebook_id}/{type}/{filename} (for older media)
	prefix := "ebooks/" + ebookID + "/"
	rows, err := r.pool.Query(ctx,
		`SELECT media_key, requested_at, not_before, attempts, last_checked_at
		 FROM ebook_media_pending_deletion
		 WHERE media_key LIKE $1
		 ORDER BY requested_at DESC`, prefix+"%")
	if err != nil {
		return nil, fmt.Errorf("query pending deletions: %w", err)
	}
	defer rows.Close()

	var items []*domain.MediaPendingDeletion
	for rows.Next() {
		var item domain.MediaPendingDeletion
		if err := rows.Scan(&item.MediaKey, &item.RequestedAt, &item.NotBefore, &item.Attempts, &item.LastCheckedAt); err != nil {
			return nil, fmt.Errorf("scan pending item: %w", err)
		}
		items = append(items, &item)
	}
	if items == nil {
		items = []*domain.MediaPendingDeletion{}
	}
	return items, nil
}

// List returns pending deletions with pagination.
func (r *MediaPendingRepository) List(ctx context.Context, limit, offset int) ([]domain.ListPendingItem, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT media_key, requested_at, not_before, attempts, last_checked_at
		 FROM ebook_media_pending_deletion
		 ORDER BY not_before ASC
		 LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("query pending deletions: %w", err)
	}
	defer rows.Close()

	var items []domain.ListPendingItem
	for rows.Next() {
		var item domain.ListPendingItem
		if err := rows.Scan(&item.MediaKey, &item.RequestedAt, &item.NotBefore, &item.Attempts, &item.LastCheckedAt); err != nil {
			return nil, fmt.Errorf("scan pending item: %w", err)
		}
		items = append(items, item)
	}
	if items == nil {
		items = []domain.ListPendingItem{}
	}
	return items, nil
}

// EnqueueOrphanedMedia enqueues media with zero references for deletion.
func (r *MediaPendingRepository) EnqueueOrphanedMedia(ctx context.Context) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_media_pending_deletion (media_key, requested_at, not_before, attempts, last_checked_at)
		 SELECT mu.media_key, now(), now() + interval '15 minutes', 0, NULL
		 FROM ebook_media_usage mu
		 LEFT JOIN ebook_media_pending_deletion pd ON pd.media_key = mu.media_key
		 WHERE mu.in_autosave = false AND mu.manual_refs = 0 AND mu.published_refs = 0
		   AND pd.media_key IS NULL`)
	if err != nil {
		return fmt.Errorf("enqueue orphaned media: %w", err)
	}
	return nil
}

// VersionMediaRepository implements repository.VersionMediaRepository using PostgreSQL.
type VersionMediaRepository struct {
	pool *pgxpool.Pool
}

// NewVersionMediaRepository creates a new VersionMediaRepository.
func NewVersionMediaRepository(pool *pgxpool.Pool) *VersionMediaRepository {
	return &VersionMediaRepository{pool: pool}
}

// Add adds a media key to a version.
func (r *VersionMediaRepository) Add(ctx context.Context, versionID, mediaKey string) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_version_media (version_id, media_key)
		 VALUES ($1, $2) ON CONFLICT DO NOTHING`,
		versionID, mediaKey)
	if err != nil {
		return fmt.Errorf("add version media: %w", err)
	}
	return nil
}

// Link links a media key to a version (alias for Add).
func (r *VersionMediaRepository) Link(ctx context.Context, versionID, mediaKey string) error {
	return r.Add(ctx, versionID, mediaKey)
}

// WithTx returns a transaction-scoped repository.
func (r *VersionMediaRepository) WithTx(tx pgx.Tx) repository.TxVersionMediaRepository {
	return NewTxVersionMediaRepository(tx)
}

// ListByVersion returns all media keys for a version.
func (r *VersionMediaRepository) ListByVersion(ctx context.Context, versionID string) ([]string, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT media_key FROM ebook_version_media WHERE version_id = $1`, versionID)
	if err != nil {
		return nil, fmt.Errorf("query version media: %w", err)
	}
	defer rows.Close()

	var keys []string
	for rows.Next() {
		var key string
		if err := rows.Scan(&key); err != nil {
			return nil, fmt.Errorf("scan media key: %w", err)
		}
		keys = append(keys, key)
	}
	return keys, nil
}

// DeleteByVersion removes all media mappings for a version.
func (r *VersionMediaRepository) DeleteByVersion(ctx context.Context, versionID string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM ebook_version_media WHERE version_id = $1`, versionID)
	if err != nil {
		return fmt.Errorf("delete version media: %w", err)
	}
	return nil
}

// TxVersionMediaRepository wraps VersionMediaRepository for transaction operations.
type TxVersionMediaRepository struct {
	tx pgx.Tx
}

// NewTxVersionMediaRepository creates a new TxVersionMediaRepository.
func NewTxVersionMediaRepository(tx pgx.Tx) *TxVersionMediaRepository {
	return &TxVersionMediaRepository{tx: tx}
}

// Add adds a media key to a version within a transaction.
func (r *TxVersionMediaRepository) Add(ctx context.Context, versionID, mediaKey string) error {
	_, err := r.tx.Exec(ctx,
		`INSERT INTO ebook_version_media (version_id, media_key)
		 VALUES ($1, $2) ON CONFLICT DO NOTHING`,
		versionID, mediaKey)
	if err != nil {
		return fmt.Errorf("add version media: %w", err)
	}
	return nil
}

// Link links a media key to a version within a transaction (alias for Add).
func (r *TxVersionMediaRepository) Link(ctx context.Context, versionID, mediaKey string) error {
	return r.Add(ctx, versionID, mediaKey)
}

// ListByVersion returns all media keys for a version within a transaction.
func (r *TxVersionMediaRepository) ListByVersion(ctx context.Context, versionID string) ([]string, error) {
	rows, err := r.tx.Query(ctx,
		`SELECT media_key FROM ebook_version_media WHERE version_id = $1`, versionID)
	if err != nil {
		return nil, fmt.Errorf("query version media: %w", err)
	}
	defer rows.Close()

	var keys []string
	for rows.Next() {
		var key string
		if err := rows.Scan(&key); err != nil {
			return nil, fmt.Errorf("scan media key: %w", err)
		}
		keys = append(keys, key)
	}
	return keys, nil
}

// DeleteByVersion removes all media mappings for a version within a transaction.
func (r *TxVersionMediaRepository) DeleteByVersion(ctx context.Context, versionID string) error {
	_, err := r.tx.Exec(ctx, `DELETE FROM ebook_version_media WHERE version_id = $1`, versionID)
	if err != nil {
		return fmt.Errorf("delete version media: %w", err)
	}
	return nil
}

// MediaAssetRepository implements repository.MediaAssetRepository using PostgreSQL.
type MediaAssetRepository struct {
	pool *pgxpool.Pool
}

// NewMediaAssetRepository creates a new MediaAssetRepository.
func NewMediaAssetRepository(pool *pgxpool.Pool) *MediaAssetRepository {
	return &MediaAssetRepository{pool: pool}
}

// Create creates a media asset record.
func (r *MediaAssetRepository) Create(ctx context.Context, asset *domain.MediaAsset) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_media_assets (media_key, file_type, mime_type, file_size, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, now())
		 ON CONFLICT (media_key) DO NOTHING`,
		asset.MediaKey, asset.FileType, asset.MimeType, asset.FileSize, asset.CreatedAt)
	if err != nil {
		return fmt.Errorf("create media asset: %w", err)
	}
	return nil
}

// Upsert creates or updates media asset metadata.
func (r *MediaAssetRepository) Upsert(ctx context.Context, asset *domain.MediaAsset) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ebook_media_assets (media_key, file_type, mime_type, file_size, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, now(), now())
		 ON CONFLICT (media_key) DO UPDATE SET file_type = EXCLUDED.file_type, mime_type = EXCLUDED.mime_type, file_size = EXCLUDED.file_size, updated_at = now()`,
		asset.MediaKey, asset.FileType, asset.MimeType, asset.FileSize)
	if err != nil {
		return fmt.Errorf("upsert media asset: %w", err)
	}
	return nil
}

// Delete removes a media asset record.
func (r *MediaAssetRepository) Delete(ctx context.Context, mediaKey string) error {
	_, err := r.pool.Exec(ctx,
		`DELETE FROM ebook_media_assets WHERE media_key = $1`,
		mediaKey)
	if err != nil {
		return fmt.Errorf("delete media asset: %w", err)
	}
	return nil
}
