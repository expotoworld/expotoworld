package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/repository/postgres"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/storage"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// VersionService handles ebook version operations.
type VersionService struct {
	pool             *pgxpool.Pool
	ebookRepo        *postgres.EbookRepository
	versionRepo      *postgres.VersionRepository
	mediaUsageRepo   *postgres.MediaUsageRepository
	versionMediaRepo *postgres.VersionMediaRepository
	s3Client         storage.S3Client
	contentBucket    string
	cdnBaseURL       string
}

// NewVersionService creates a new VersionService.
func NewVersionService(
	pool *pgxpool.Pool,
	ebookRepo *postgres.EbookRepository,
	versionRepo *postgres.VersionRepository,
	mediaUsageRepo *postgres.MediaUsageRepository,
	versionMediaRepo *postgres.VersionMediaRepository,
	s3Client storage.S3Client,
	contentBucket string,
	cdnBaseURL string,
) *VersionService {
	return &VersionService{
		pool:             pool,
		ebookRepo:        ebookRepo,
		versionRepo:      versionRepo,
		mediaUsageRepo:   mediaUsageRepo,
		versionMediaRepo: versionMediaRepo,
		s3Client:         s3Client,
		contentBucket:    contentBucket,
		cdnBaseURL:       cdnBaseURL,
	}
}

// ListVersions returns all versions for an ebook, optionally filtered by kind.
func (s *VersionService) ListVersions(ctx context.Context, req *domain.ListVersionsRequest) (*domain.ListVersionsResponse, error) {
	// Look up ebook by slug to get UUID
	ebook, err := s.ebookRepo.GetBySlug(ctx, req.EbookID)
	if err != nil {
		return nil, fmt.Errorf("get ebook: %w", err)
	}

	versions, err := s.versionRepo.ListByEbookID(ctx, ebook.ID)
	if err != nil {
		return nil, fmt.Errorf("list versions: %w", err)
	}

	// Filter by kind if specified
	if req.Kind != "" {
		filtered := make([]*domain.Version, 0)
		for _, v := range versions {
			if string(v.Kind) == req.Kind {
				filtered = append(filtered, v)
			}
		}
		versions = filtered
	}

	// Find current published version by looking for kind = 'published'
	var currentVersionID *string
	for _, v := range versions {
		if v.Kind == domain.VersionKindPublished {
			currentVersionID = &v.ID
			break
		}
	}

	return &domain.ListVersionsResponse{
		Versions:         versions,
		CurrentVersionID: currentVersionID,
	}, nil
}

// CreateVersion creates a new manual version from the current autosave content in the database.
// Autosave content is stored in ebooks.content, manual/published versions are stored in S3.
func (s *VersionService) CreateVersion(ctx context.Context, req *domain.CreateVersionRequest) (*domain.CreateVersionResponse, error) {
	// Look up ebook by slug to get UUID and current content
	ebook, err := s.ebookRepo.GetBySlug(ctx, req.EbookID)
	if err != nil {
		return nil, fmt.Errorf("get ebook: %w", err)
	}

	// Get content from database (autosave is stored in ebooks.content)
	content := ebook.Content
	if len(content) == 0 {
		return nil, fmt.Errorf("no content to save as version")
	}

	// Generate version ID
	versionID := uuid.New().String()

	// Generate S3 key using timestamp-based path like old backend
	s3Key := fmt.Sprintf("ebook/versions/manual/%d.json", time.Now().UnixNano())

	// Execute in transaction
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Create version record (use UUID ebook.ID, not slug)
	// Only 'manual' and 'published' are valid kinds in the database
	version := &domain.Version{
		ID:        versionID,
		EbookID:   ebook.ID,
		Kind:      domain.VersionKindManual,
		Label:     req.Label,
		S3Key:     s3Key,
		CreatedAt: time.Now(),
	}

	txVersionRepo := s.versionRepo.WithTx(tx)
	if err := txVersionRepo.Create(ctx, version); err != nil {
		return nil, fmt.Errorf("create version: %w", err)
	}

	// Store content in version bucket using timestamp-based path
	if err := s.s3Client.PutObjectToBucket(ctx, s.contentBucket, s3Key, content, "application/json"); err != nil {
		return nil, fmt.Errorf("store version content: %w", err)
	}

	// Link media to version
	mediaKeys := ExtractMediaKeys(content)
	txVersionMediaRepo := s.versionMediaRepo.WithTx(tx)
	txMediaUsageRepo := s.mediaUsageRepo.WithTx(tx)
	for _, key := range mediaKeys {
		if err := txVersionMediaRepo.Link(ctx, versionID, key); err != nil {
			return nil, fmt.Errorf("link media %s: %w", key, err)
		}
		// Increment manual_refs for this media key
		if err := txMediaUsageRepo.IncrementManualRefs(ctx, ebook.ID, key); err != nil {
			return nil, fmt.Errorf("increment manual refs for %s: %w", key, err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit transaction: %w", err)
	}

	return &domain.CreateVersionResponse{
		Version: version,
	}, nil
}

// PublishVersion creates a new published version from an existing manual version.
// The original manual version is preserved, and a new published version is created.
// Any previously published version is demoted to manual.
func (s *VersionService) PublishVersion(ctx context.Context, req *domain.PublishVersionRequest) (*domain.PublishVersionResponse, error) {
	// Look up ebook by slug to get UUID
	ebook, err := s.ebookRepo.GetBySlug(ctx, req.EbookID)
	if err != nil {
		return nil, fmt.Errorf("get ebook: %w", err)
	}

	// Get the source version to publish from
	sourceVersion, err := s.versionRepo.GetByID(ctx, req.VersionID)
	if err != nil {
		return nil, domain.ErrVersionNotFound
	}

	// Verify ebook matches (compare UUIDs)
	if sourceVersion.EbookID != ebook.ID {
		return nil, domain.ErrVersionNotFound
	}

	// Fetch content from S3 using the source version's S3Key
	content, err := s.s3Client.GetObjectFromBucket(ctx, s.contentBucket, sourceVersion.S3Key)
	if err != nil {
		return nil, fmt.Errorf("get source version content: %w", err)
	}

	// Generate new version ID and S3 key
	newVersionID := uuid.New().String()
	newS3Key := fmt.Sprintf("ebook/versions/published/%d.json", time.Now().UnixNano())

	// Execute in transaction
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	txVersionRepo := s.versionRepo.WithTx(tx)

	// NOTE: We do NOT demote existing published versions to manual.
	// Multiple published versions can coexist. Each publish creates a new 
	// independent published version without affecting existing ones.

	// Create the new published version
	// Use provided label, or fall back to source version label
	label := req.Label
	if label == "" {
		label = sourceVersion.Label
	}
	newVersion := &domain.Version{
		ID:        newVersionID,
		EbookID:   ebook.ID,
		Kind:      domain.VersionKindPublished,
		Label:     label,
		S3Key:     newS3Key,
		CreatedAt: time.Now(),
	}

	if err := txVersionRepo.Create(ctx, newVersion); err != nil {
		return nil, fmt.Errorf("create published version: %w", err)
	}

	// Store content in S3 with new key
	if err := s.s3Client.PutObjectToBucket(ctx, s.contentBucket, newS3Key, content, "application/json"); err != nil {
		return nil, fmt.Errorf("store published content: %w", err)
	}

	// Link media to new version
	mediaKeys := ExtractMediaKeys(content)
	txVersionMediaRepo := s.versionMediaRepo.WithTx(tx)
	txMediaUsageRepo := s.mediaUsageRepo.WithTx(tx)
	for _, key := range mediaKeys {
		if err := txVersionMediaRepo.Link(ctx, newVersionID, key); err != nil {
			return nil, fmt.Errorf("link media %s: %w", key, err)
		}
		// Increment published_refs for this media key
		if err := txMediaUsageRepo.IncrementPublishedRefs(ctx, req.EbookID, key); err != nil {
			return nil, fmt.Errorf("increment published refs for %s: %w", key, err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit transaction: %w", err)
	}

	return &domain.PublishVersionResponse{
		Version:   newVersion,
		MediaKeys: mediaKeys,
	}, nil
}

// RestoreVersion restores a version's content to the ebook's autosave (stored in database).
func (s *VersionService) RestoreVersion(ctx context.Context, req *domain.RestoreVersionRequest) (*domain.RestoreVersionResponse, error) {
	// Look up ebook by slug to get UUID
	ebook, err := s.ebookRepo.GetBySlug(ctx, req.EbookID)
	if err != nil {
		return nil, fmt.Errorf("get ebook: %w", err)
	}

	// Get the version
	version, err := s.versionRepo.GetByID(ctx, req.VersionID)
	if err != nil {
		return nil, domain.ErrVersionNotFound
	}

	// Verify ebook matches (compare UUIDs)
	if version.EbookID != ebook.ID {
		return nil, domain.ErrVersionNotFound
	}

	// Load version content from S3 using the version's stored S3Key
	content, err := s.s3Client.GetObjectFromBucket(ctx, s.contentBucket, version.S3Key)
	if err != nil {
		return nil, fmt.Errorf("get version content: %w", err)
	}

	// Update the ebook's content in the database (autosave is stored in ebooks.content)
	if err := s.ebookRepo.UpdateContent(ctx, ebook.Slug, content); err != nil {
		return nil, fmt.Errorf("restore to autosave: %w", err)
	}

	// Sync media usage from restored content
	mediaKeys := ExtractMediaKeys(content)
	if err := s.mediaUsageRepo.ResetAll(ctx, ebook.ID); err != nil {
		return nil, fmt.Errorf("reset media usage: %w", err)
	}
	for _, key := range mediaKeys {
		if err := s.mediaUsageRepo.UpsertAutosave(ctx, ebook.ID, key, true); err != nil {
			return nil, fmt.Errorf("update autosave media %s: %w", key, err)
		}
	}

	return &domain.RestoreVersionResponse{
		Version:         version,
		Content:         json.RawMessage(content),
		RestoredContent: json.RawMessage(content),
	}, nil
}

// DeleteVersion deletes a version from both database and S3.
func (s *VersionService) DeleteVersion(ctx context.Context, req *domain.DeleteVersionRequest) error {
	// Look up ebook by slug to get UUID
	ebook, err := s.ebookRepo.GetBySlug(ctx, req.EbookID)
	if err != nil {
		return fmt.Errorf("get ebook: %w", err)
	}

	// Get version to verify it exists and belongs to this ebook
	version, err := s.versionRepo.GetByID(ctx, req.VersionID)
	if err != nil {
		return domain.ErrVersionNotFound
	}
	if version.EbookID != ebook.ID {
		return domain.ErrVersionNotFound
	}

	// Execute in transaction
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Get media keys linked to this version BEFORE deleting
	txVersionMediaRepo := s.versionMediaRepo.WithTx(tx)
	mediaKeys, err := txVersionMediaRepo.ListByVersion(ctx, req.VersionID)
	if err != nil {
		return fmt.Errorf("list version media: %w", err)
	}

	// Delete version media links
	if err := txVersionMediaRepo.DeleteByVersion(ctx, req.VersionID); err != nil {
		return fmt.Errorf("delete version media: %w", err)
	}

	// Decrement the appropriate refs for each media key
	txMediaUsageRepo := postgres.NewTxMediaUsageRepository(tx)
	for _, key := range mediaKeys {
		if version.Kind == domain.VersionKindPublished {
			// Decrement published_refs for published versions
			if err := txMediaUsageRepo.DecrementPublishedRefs(ctx, ebook.ID, key); err != nil {
				return fmt.Errorf("decrement published refs for %s: %w", key, err)
			}
		} else {
			// Decrement manual_refs for manual versions
			if err := txMediaUsageRepo.DecrementManualRefs(ctx, ebook.ID, key); err != nil {
				return fmt.Errorf("decrement manual refs for %s: %w", key, err)
			}
		}
	}

	// Delete version record
	txVersionRepo := s.versionRepo.WithTx(tx)
	if err := txVersionRepo.Delete(ctx, req.VersionID); err != nil {
		return fmt.Errorf("delete version: %w", err)
	}

	// Delete version content from S3 using the stored S3Key
	if err := s.s3Client.DeleteObjectFromBucket(ctx, s.contentBucket, version.S3Key); err != nil {
		// Log but don't fail - data cleanup can happen later
		fmt.Printf("warning: failed to delete version content %s: %v\n", version.S3Key, err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit transaction: %w", err)
	}

	return nil
}

// GetVersionContent retrieves the content of a specific version.
func (s *VersionService) GetVersionContent(ctx context.Context, ebookID, versionID string) (json.RawMessage, error) {
	// Look up ebook by slug to get UUID
	ebook, err := s.ebookRepo.GetBySlug(ctx, ebookID)
	if err != nil {
		return nil, fmt.Errorf("get ebook: %w", err)
	}

	// Verify version exists and belongs to ebook
	version, err := s.versionRepo.GetByID(ctx, versionID)
	if err != nil {
		return nil, domain.ErrVersionNotFound
	}
	if version.EbookID != ebook.ID {
		return nil, domain.ErrVersionNotFound
	}

	// Load content from S3 using the version's stored S3Key
	content, err := s.s3Client.GetObjectFromBucket(ctx, s.contentBucket, version.S3Key)
	if err != nil {
		return nil, fmt.Errorf("get version content: %w", err)
	}

	return content, nil
}

// UpdateVersionLabel updates the label of a version.
func (s *VersionService) UpdateVersionLabel(ctx context.Context, ebookID, versionID, label string) error {
	// Look up ebook by slug to get UUID
	ebook, err := s.ebookRepo.GetBySlug(ctx, ebookID)
	if err != nil {
		return fmt.Errorf("get ebook: %w", err)
	}

	// Verify version exists and belongs to ebook
	version, err := s.versionRepo.GetByID(ctx, versionID)
	if err != nil {
		return domain.ErrVersionNotFound
	}
	if version.EbookID != ebook.ID {
		return domain.ErrVersionNotFound
	}

	// Update the label
	version.Label = label
	if err := s.versionRepo.Update(ctx, version); err != nil {
		return fmt.Errorf("update version label: %w", err)
	}

	return nil
}
