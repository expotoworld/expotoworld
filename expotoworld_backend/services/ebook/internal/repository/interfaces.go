// Package repository defines the interfaces for data access.
package repository

import (
	"context"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/jackc/pgx/v5"
)

// EbookRepository defines operations for ebook persistence.
type EbookRepository interface {
	// GetByID returns the ebook by UUID.
	GetByID(ctx context.Context, id string) (*domain.Ebook, error)

	// GetBySlug returns the ebook by slug.
	GetBySlug(ctx context.Context, slug string) (*domain.Ebook, error)

	// Create creates a new ebook.
	Create(ctx context.Context, ebook *domain.Ebook) error

	// UpdateContent updates the ebook's content.
	UpdateContent(ctx context.Context, slug string, content []byte) error

	// UpdateTimestamp updates the ebook's updated_at timestamp.
	UpdateTimestamp(ctx context.Context, slug string) error

	// WithTx returns a transaction-scoped repository.
	WithTx(tx pgx.Tx) TxEbookRepository
}

// TxEbookRepository defines transaction-scoped ebook operations.
type TxEbookRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Ebook, error)
	GetBySlug(ctx context.Context, slug string) (*domain.Ebook, error)
	UpdateContent(ctx context.Context, slug string, content []byte) error
}

// VersionRepository defines operations for version persistence.
type VersionRepository interface {
	// GetByID returns a version by ID.
	GetByID(ctx context.Context, id string) (*domain.Version, error)

	// ListByEbook returns all versions for an ebook.
	ListByEbook(ctx context.Context, ebookID string) ([]*domain.Version, error)

	// ListByEbookID returns all versions for an ebook (alias).
	ListByEbookID(ctx context.Context, ebookID string) ([]*domain.Version, error)

	// Create creates a new version.
	Create(ctx context.Context, version *domain.Version) error

	// Update updates a version.
	Update(ctx context.Context, version *domain.Version) error

	// UpdateKind updates only the kind field of a version.
	UpdateKind(ctx context.Context, id string, kind domain.VersionKind) error

	// Delete deletes a version by ID.
	Delete(ctx context.Context, id string) error

	// WithTx returns a transaction-scoped repository.
	WithTx(tx pgx.Tx) TxVersionRepository
}

// TxVersionRepository defines transaction-scoped version operations.
type TxVersionRepository interface {
	Create(ctx context.Context, version *domain.Version) error
	UpdateKind(ctx context.Context, id string, kind domain.VersionKind) error
	Delete(ctx context.Context, id string) error
}

// MediaUsageRepository defines operations for tracking media usage.
type MediaUsageRepository interface {
	// Get returns media usage for the given ebook and key.
	Get(ctx context.Context, ebookID, mediaKey string) (*domain.MediaUsage, error)

	// UpsertAutosave marks a media key as used in autosave.
	UpsertAutosave(ctx context.Context, ebookID, mediaKey string, inAutosave bool) error

	// UpsertPublished marks a media key as used in published version.
	UpsertPublished(ctx context.Context, ebookID, mediaKey string, inPublished bool) error

	// IncrementManualRefs increments the manual reference count.
	IncrementManualRefs(ctx context.Context, ebookID, mediaKey string) error

	// DecrementManualRefs decrements the manual reference count.
	DecrementManualRefs(ctx context.Context, ebookID, mediaKey string) error

	// IncrementPublishedRefs increments the published reference count.
	IncrementPublishedRefs(ctx context.Context, ebookID, mediaKey string) error

	// DecrementPublishedRefs decrements the published reference count.
	DecrementPublishedRefs(ctx context.Context, ebookID, mediaKey string) error

	// UpdateLastSeen updates the last seen timestamp.
	UpdateLastSeen(ctx context.Context, ebookID, mediaKey string) error

	// ResetAll resets all autosave flags for an ebook.
	ResetAll(ctx context.Context, ebookID string) error

	// Delete removes a media usage entry.
	Delete(ctx context.Context, ebookID, mediaKey string) error

	// DeleteByEbook removes all media usage entries for an ebook.
	DeleteByEbook(ctx context.Context, ebookID string) error

	// WithTx returns a transaction-scoped repository.
	WithTx(tx pgx.Tx) TxMediaUsageRepository
}

// TxMediaUsageRepository defines transaction-scoped media usage operations.
type TxMediaUsageRepository interface {
	// IncrementManualRefs increments the manual reference count within a transaction.
	IncrementManualRefs(ctx context.Context, ebookID, mediaKey string) error
	// DecrementManualRefs decrements the manual reference count within a transaction.
	DecrementManualRefs(ctx context.Context, ebookID, mediaKey string) error
	// IncrementPublishedRefs increments the published reference count within a transaction.
	IncrementPublishedRefs(ctx context.Context, ebookID, mediaKey string) error
	// DecrementPublishedRefs decrements the published reference count within a transaction.
	DecrementPublishedRefs(ctx context.Context, ebookID, mediaKey string) error
	// UpsertPublished marks a media key as used in published version.
	UpsertPublished(ctx context.Context, ebookID, mediaKey string, inPublished bool) error
}

// MediaPendingRepository defines operations for pending media deletions.
type MediaPendingRepository interface {
	// Create creates a pending deletion record.
	Create(ctx context.Context, pending *domain.MediaPending) error

	// Schedule schedules a media key for deletion.
	Schedule(ctx context.Context, mediaKey string, ttlMinutes int) error

	// List returns pending deletions with pagination.
	List(ctx context.Context, limit, offset int) ([]domain.ListPendingItem, error)

	// ListByEbook returns pending deletions for an ebook.
	ListByEbook(ctx context.Context, ebookID string) ([]*domain.MediaPendingDeletion, error)

	// EnqueueOrphanedMedia enqueues media with zero references for deletion.
	EnqueueOrphanedMedia(ctx context.Context) error
}

// VersionMediaRepository defines operations for version-media mappings.
type VersionMediaRepository interface {
	// Add adds a media key to a version.
	Add(ctx context.Context, versionID, mediaKey string) error

	// Link links a media key to a version (alias for Add).
	Link(ctx context.Context, versionID, mediaKey string) error

	// ListByVersion returns all media keys for a version.
	ListByVersion(ctx context.Context, versionID string) ([]string, error)

	// DeleteByVersion removes all media mappings for a version.
	DeleteByVersion(ctx context.Context, versionID string) error

	// WithTx returns a transaction-scoped repository.
	WithTx(tx pgx.Tx) TxVersionMediaRepository
}

// TxVersionMediaRepository defines transaction-scoped version-media operations.
type TxVersionMediaRepository interface {
	Link(ctx context.Context, versionID, mediaKey string) error
	ListByVersion(ctx context.Context, versionID string) ([]string, error)
	DeleteByVersion(ctx context.Context, versionID string) error
}

// MediaAssetRepository defines operations for media asset metadata.
type MediaAssetRepository interface {
	// Create creates a media asset record.
	Create(ctx context.Context, asset *domain.MediaAsset) error

	// Upsert creates or updates media asset metadata.
	Upsert(ctx context.Context, asset *domain.MediaAsset) error

	// Delete removes a media asset record.
	Delete(ctx context.Context, mediaKey string) error
}
