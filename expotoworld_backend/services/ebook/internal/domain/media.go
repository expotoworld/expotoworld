// Package domain contains the business entities for the ebook service.
package domain

import (
	"time"
)

// MediaType represents the type of media file.
type MediaType string

const (
	MediaTypeImage MediaType = "image"
	MediaTypeVideo MediaType = "video"
	MediaTypeAudio MediaType = "audio"
)

// MediaAsset represents metadata for an uploaded media file.
type MediaAsset struct {
	MediaKey  string    `json:"media_key"`
	S3Key     string    `json:"s3_key"`
	EbookID   string    `json:"ebook_id"`
	MediaType string    `json:"media_type"`
	FileType  string    `json:"file_type"`
	Filename  string    `json:"filename"`
	MimeType  string    `json:"mime_type"`
	FileSize  int64     `json:"file_size"`
	Size      int64     `json:"size"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// MediaUsage tracks references to media files across ebook versions.
type MediaUsage struct {
	MediaKey      string    `json:"media_key"`
	EbookID       string    `json:"ebook_id"`
	InAutosave    bool      `json:"in_autosave"`
	InPublished   bool      `json:"in_published"`
	ManualRefs    int       `json:"manual_refs"`
	PublishedRefs int       `json:"published_refs"`
	LastSeenAt    time.Time `json:"last_seen_at"`
}

// MediaPending represents a media file scheduled for deletion.
type MediaPending struct {
	S3Key     string     `json:"s3_key"`
	EbookID   string     `json:"ebook_id"`
	MarkedAt  time.Time  `json:"marked_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`
}

// MediaPendingDeletion represents a media file scheduled for deletion.
type MediaPendingDeletion struct {
	MediaKey      string     `json:"media_key"`
	RequestedAt   time.Time  `json:"requested_at"`
	NotBefore     time.Time  `json:"not_before"`
	Attempts      int        `json:"attempts"`
	LastCheckedAt *time.Time `json:"last_checked_at"`
}

// VersionMedia represents the mapping between versions and their media files.
type VersionMedia struct {
	VersionID string `json:"version_id"`
	MediaKey  string `json:"media_key"`
}

// UploadImageResponse represents the response for uploading an image.
type UploadImageResponse struct {
	URL string `json:"url"`
}

// UploadMediaRequest represents the request for uploading media.
type UploadMediaRequest struct {
	EbookID  string
	UserID   string
	Filename string
	MimeType string
	Data     []byte
}

// UploadMediaResponse represents the response for uploading any media type.
type UploadMediaResponse struct {
	S3Key    string `json:"s3_key"`
	MediaKey string `json:"media_key"`
	URL      string `json:"url"`
	Filename string `json:"filename"`
	FileType string `json:"file_type"`
}

// DeleteMediaRequest represents the request for deleting media.
type DeleteMediaRequest struct {
	EbookID  string `json:"ebook_id"`
	UserID   string `json:"user_id"`
	S3Key    string `json:"s3_key"`
	MediaKey string `json:"media_key"`
	MediaURL string `json:"media_url"` // Legacy field for backwards compatibility
	ImageURL string `json:"image_url"` // Legacy field for backwards compatibility
}

// ReindexMediaResponse represents the response for reindexing media.
type ReindexMediaResponse struct {
	EbookID      string `json:"ebook_id"`
	TotalFound   int    `json:"total_found"`
	TotalTracked int    `json:"total_tracked"`
}

// CleanupMediaResponse represents the response for cleaning up orphaned media.
type CleanupMediaResponse struct {
	EbookID      string `json:"ebook_id"`
	TotalScanned int    `json:"total_scanned"`
	TotalDeleted int    `json:"total_deleted"`
	TotalErrors  int    `json:"total_errors"`
}

// DeleteMediaResponse represents the response for deleting media.
type DeleteMediaResponse struct {
	Success   bool      `json:"success"`
	MediaKey  string    `json:"media_key"`
	DeletedAt time.Time `json:"deleted_at"`
}

// ReindexResponse represents the response for admin reindex operation.
type ReindexResponse struct {
	Success     bool      `json:"success"`
	ReindexedAt time.Time `json:"reindexed_at"`
}

// ListPendingItem represents a pending deletion item in list responses.
type ListPendingItem struct {
	MediaKey      string     `json:"media_key"`
	RequestedAt   time.Time  `json:"requested_at"`
	NotBefore     time.Time  `json:"not_before"`
	Attempts      int        `json:"attempts"`
	LastCheckedAt *time.Time `json:"last_checked_at"`
}

// ListPendingResponse represents the response for listing pending deletions.
type ListPendingResponse struct {
	Items  []ListPendingItem `json:"items"`
	Limit  int               `json:"limit"`
	Offset int               `json:"offset"`
}

// AllowedImageTypes contains the allowed MIME types for image uploads.
var AllowedImageTypes = map[string]bool{
	"image/jpeg":    true,
	"image/jpg":     true,
	"image/png":     true,
	"image/svg+xml": true,
	"image/gif":     true,
	"image/heic":    true,
}

// AllowedVideoTypes contains the allowed MIME types for video uploads.
var AllowedVideoTypes = map[string]bool{
	"video/mp4":       true,
	"video/quicktime": true,
}

// AllowedAudioTypes contains the allowed MIME types for audio uploads.
var AllowedAudioTypes = map[string]bool{
	"audio/mpeg":  true,
	"audio/mp4":   true,
	"audio/x-m4a": true,
	"audio/wav":   true,
}
