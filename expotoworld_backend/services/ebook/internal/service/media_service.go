package service

import (
	"context"
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/repository"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/storage"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Supported media types and their extensions
var supportedMediaTypes = map[string][]string{
	"image": {".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg"},
	"video": {".mp4", ".webm", ".mov"},
	"audio": {".mp3", ".wav", ".ogg", ".m4a"},
}

// MediaService handles media upload and management operations.
type MediaService struct {
	pool             *pgxpool.Pool
	mediaUsageRepo   repository.MediaUsageRepository
	mediaPendingRepo repository.MediaPendingRepository
	mediaAssetRepo   repository.MediaAssetRepository
	s3Client         storage.S3Client
	cdnBaseURL       string
	mediaBucket      string
	mediaBasePath    string // Base path in S3, e.g., "ebooks/huashangdao"
}

// NewMediaService creates a new MediaService.
func NewMediaService(
	pool *pgxpool.Pool,
	mediaUsageRepo repository.MediaUsageRepository,
	mediaPendingRepo repository.MediaPendingRepository,
	mediaAssetRepo repository.MediaAssetRepository,
	s3Client storage.S3Client,
	cdnBaseURL string,
	mediaBucket string,
	mediaBasePath string,
) *MediaService {
	return &MediaService{
		pool:             pool,
		mediaUsageRepo:   mediaUsageRepo,
		mediaPendingRepo: mediaPendingRepo,
		mediaAssetRepo:   mediaAssetRepo,
		s3Client:         s3Client,
		cdnBaseURL:       cdnBaseURL,
		mediaBucket:      mediaBucket,
		mediaBasePath:    mediaBasePath,
	}
}

// UploadMedia uploads a media file and tracks it.
func (s *MediaService) UploadMedia(ctx context.Context, req *domain.UploadMediaRequest, file multipart.File, header *multipart.FileHeader) (*domain.UploadMediaResponse, error) {
	// Validate media type
	ext := strings.ToLower(filepath.Ext(header.Filename))
	mediaType := s.detectMediaType(ext)
	if mediaType == "" {
		return nil, domain.ErrInvalidMediaType
	}

	// Generate unique filename with timestamp
	fileID := fmt.Sprintf("%d", time.Now().UnixNano())
	newFilename := fileID + ext
	
	// Map media type to S3 folder - use plural forms matching existing structure
	typeFolder := "images" // default
	switch mediaType {
	case "video":
		typeFolder = "videos"
	case "audio":
		typeFolder = "audio"
	case "image":
		typeFolder = "images"
	}
	
	// S3 path: {mediaBasePath}/{images|videos|audio}/{filename}
	// e.g., ebooks/huashangdao/images/1234567890.jpg
	// Using configured mediaBasePath instead of ebookID to maintain S3 structure compatibility
	s3Key := fmt.Sprintf("%s/%s/%s", s.mediaBasePath, typeFolder, newFilename)

	// Read file content
	content := make([]byte, header.Size)
	if _, err := file.Read(content); err != nil {
		return nil, fmt.Errorf("read file: %w", err)
	}

	// Determine content type
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	// Upload to S3
	if err := s.s3Client.PutObject(ctx, s3Key, content, contentType); err != nil {
		return nil, fmt.Errorf("upload to s3: %w", err)
	}

	// Track media usage (autosave = true since it's being added to draft)
	if err := s.mediaUsageRepo.UpsertAutosave(ctx, req.EbookID, s3Key, true); err != nil {
		return nil, fmt.Errorf("track media usage: %w", err)
	}

	// Track in media assets table
	// Field mapping: MediaKey is S3 key, FileType is media type category,
	// MimeType is content type, FileSize is file size in bytes
	asset := &domain.MediaAsset{
		MediaKey:  s3Key,       // S3 key is the primary key
		FileType:  mediaType,   // "image", "video", or "audio"
		MimeType:  contentType, // MIME type from header
		FileSize:  header.Size, // File size in bytes
		CreatedAt: time.Now(),
	}
	if err := s.mediaAssetRepo.Create(ctx, asset); err != nil {
		// Non-fatal: asset tracking is supplementary
		fmt.Printf("warning: failed to track media asset: %v\n", err)
	}

	return &domain.UploadMediaResponse{
		S3Key:    s3Key,
		URL:      fmt.Sprintf("%s/%s", s.cdnBaseURL, s3Key),
		Filename: newFilename,
	}, nil
}

// DeleteMedia marks media as removed from the editor (autosave).
// When media is removed from the editor, it sets in_autosave=false.
// The database trigger (fn_check_media_pending_deletion) automatically handles
// scheduling pending deletion when ALL usage indicators are false/zero:
// - in_autosave=false AND manual_refs=0 AND published_refs=0
// The Lambda cleanup job will then delete from S3, assets, and usage tables.
func (s *MediaService) DeleteMedia(ctx context.Context, req *domain.DeleteMediaRequest) error {
	// Check if media is tracked in usage table
	usage, err := s.mediaUsageRepo.Get(ctx, req.EbookID, req.S3Key)
	if err != nil || usage == nil {
		// Media not tracked, safe to delete directly from S3 and assets
		if delErr := s.s3Client.DeleteObject(ctx, req.S3Key); delErr != nil {
			return fmt.Errorf("delete from s3: %w", delErr)
		}
		// Clean up media assets
		if delErr := s.mediaAssetRepo.Delete(ctx, req.S3Key); delErr != nil {
			fmt.Printf("warning: failed to delete media asset: %v\n", delErr)
		}
		return nil
	}

	// Mark as removed from autosave - the database trigger will automatically
	// schedule pending deletion if all refs are also 0, or remove from pending
	// if media is still referenced by versions
	if err := s.mediaUsageRepo.UpsertAutosave(ctx, req.EbookID, req.S3Key, false); err != nil {
		return fmt.Errorf("update autosave flag: %w", err)
	}

	return nil
}

// ListPendingDeletions lists media marked for deletion but still in published versions.
func (s *MediaService) ListPendingDeletions(ctx context.Context, ebookID string) ([]*domain.MediaPendingDeletion, error) {
	return s.mediaPendingRepo.ListByEbook(ctx, ebookID)
}

// detectMediaType returns the media type category for an extension.
func (s *MediaService) detectMediaType(ext string) string {
	for mediaType, extensions := range supportedMediaTypes {
		for _, e := range extensions {
			if e == ext {
				return mediaType
			}
		}
	}
	return ""
}

// CleanupOrphanedMedia schedules orphaned media for pending deletion.
// Media not tracked in usage table is deleted immediately.
// Media not referenced in any version or autosave is scheduled via database trigger.
// This should be run as a background job, not synchronously.
func (s *MediaService) CleanupOrphanedMedia(ctx context.Context, ebookID string) (*domain.CleanupMediaResponse, error) {
	// List all media in S3
	prefix := fmt.Sprintf("ebooks/%s/media/", ebookID)
	s3Keys, err := s.s3Client.ListObjects(ctx, prefix)
	if err != nil {
		return nil, fmt.Errorf("list s3 objects: %w", err)
	}

	scheduled := 0
	deleted := 0
	errors := 0

	for _, key := range s3Keys {
		// Check if media is tracked
		usage, err := s.mediaUsageRepo.Get(ctx, ebookID, key)
		if err != nil {
			// Not tracked, candidate for immediate deletion
			if err := s.s3Client.DeleteObject(ctx, key); err != nil {
				errors++
				continue
			}
			deleted++
			continue
		}

		// Check if orphaned (not in autosave and no manual/published refs)
		// The database trigger will handle scheduling to pending deletion
		if !usage.InAutosave && usage.ManualRefs == 0 && usage.PublishedRefs == 0 {
			// Trigger an UPDATE to invoke the database trigger
			// This will schedule the media for pending deletion via trigger
			if err := s.mediaUsageRepo.UpsertAutosave(ctx, ebookID, key, false); err != nil {
				errors++
				continue
			}
			scheduled++
		}
	}

	return &domain.CleanupMediaResponse{
		EbookID:      ebookID,
		TotalScanned: len(s3Keys),
		TotalDeleted: deleted + scheduled, // Both immediate and scheduled count as "processed"
		TotalErrors:  errors,
	}, nil
}
