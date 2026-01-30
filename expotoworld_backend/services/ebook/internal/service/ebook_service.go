// Package service implements the business logic for the ebook service.
package service

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/repository"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/storage"
	"github.com/jackc/pgx/v5/pgxpool"
)

// EbookService handles ebook draft operations.
type EbookService struct {
	pool           *pgxpool.Pool
	ebookRepo      repository.EbookRepository
	versionRepo    repository.VersionRepository
	mediaUsageRepo repository.MediaUsageRepository
	s3Client       storage.S3Client
	cdnBaseURL     string
}

// NewEbookService creates a new EbookService.
func NewEbookService(
	pool *pgxpool.Pool,
	ebookRepo repository.EbookRepository,
	versionRepo repository.VersionRepository,
	mediaUsageRepo repository.MediaUsageRepository,
	s3Client storage.S3Client,
	cdnBaseURL string,
) *EbookService {
	return &EbookService{
		pool:           pool,
		ebookRepo:      ebookRepo,
		versionRepo:    versionRepo,
		mediaUsageRepo: mediaUsageRepo,
		s3Client:       s3Client,
		cdnBaseURL:     cdnBaseURL,
	}
}

// GetDraft retrieves the current draft for an ebook by slug.
// Note: This service only supports the single 'main' ebook - it does not auto-create new ebooks.
func (s *EbookService) GetDraft(ctx context.Context, slug, userID string) (*domain.GetDraftResponse, error) {
	// Get the ebook by slug
	ebook, err := s.ebookRepo.GetBySlug(ctx, slug)
	if err != nil {
		// Return the error (ErrEbookNotFound will be converted to 404 by the handler)
		return nil, err
	}

	return &domain.GetDraftResponse{
		EbookID:    ebook.ID,
		Slug:       ebook.Slug,
		Title:      ebook.Title,
		Content:    ebook.Content,
		CDNBaseURL: s.cdnBaseURL,
	}, nil
}

// SaveDraft saves the current draft content to the database.
func (s *EbookService) SaveDraft(ctx context.Context, req *domain.SaveDraftRequest) (*domain.SaveDraftResponse, error) {
	// Update content in database
	if err := s.ebookRepo.UpdateContent(ctx, req.EbookID, req.Content); err != nil {
		return nil, fmt.Errorf("update content: %w", err)
	}

	// Extract and track media from content
	if err := s.syncMediaUsage(ctx, req.EbookID, req.Content); err != nil {
		// Log but don't fail - media tracking is non-critical
		fmt.Printf("warning: sync media usage: %v\n", err)
	}

	return &domain.SaveDraftResponse{
		Success:   true,
		SavedAt:   time.Now(),
		MediaKeys: ExtractMediaKeys(req.Content),
	}, nil
}

// syncMediaUsage updates the media usage tracking based on content.
func (s *EbookService) syncMediaUsage(ctx context.Context, ebookID string, content json.RawMessage) error {
	mediaKeys := ExtractMediaKeys(content)

	// Reset all autosave flags for this ebook's media
	if err := s.mediaUsageRepo.ResetAll(ctx, ebookID); err != nil {
		return fmt.Errorf("reset media usage: %w", err)
	}

	// Update autosave flag for each media key in content
	for _, key := range mediaKeys {
		if err := s.mediaUsageRepo.UpsertAutosave(ctx, ebookID, key, true); err != nil {
			return fmt.Errorf("upsert autosave for %s: %w", key, err)
		}
	}

	return nil
}

// ExtractMediaKeys extracts media keys from JSON content.
// It looks for CDN URLs in the content and extracts the relative paths.
func ExtractMediaKeys(content json.RawMessage) []string {
	var keys []string
	seen := make(map[string]bool)

	// Simple extraction: look for patterns like "ebooks/xxx/media/yyy"
	contentStr := string(content)

	// Find all media references
	patterns := []string{
		"ebooks/",
	}

	for _, pattern := range patterns {
		idx := 0
		for {
			pos := strings.Index(contentStr[idx:], pattern)
			if pos == -1 {
				break
			}
			startIdx := idx + pos

			// Find the end of the path (quote, space, or special chars)
			endIdx := startIdx
			for endIdx < len(contentStr) {
				c := contentStr[endIdx]
				if c == '"' || c == '\'' || c == ' ' || c == '>' || c == ')' || c == '\\' {
					break
				}
				endIdx++
			}

			key := contentStr[startIdx:endIdx]
			// Match actual S3 structure: ebooks/{slug}/{images|videos|audio}/filename
			if !seen[key] && (strings.Contains(key, "/images/") || strings.Contains(key, "/videos/") || strings.Contains(key, "/audio/")) {
				seen[key] = true
				keys = append(keys, key)
			}

			idx = endIdx
		}
	}

	return keys
}
