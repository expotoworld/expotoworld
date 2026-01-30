package domain

import (
	"encoding/json"
	"time"
)

// VersionKind represents the type of version (manual or auto).
type VersionKind string

const (
	VersionKindManual    VersionKind = "manual"
	VersionKindAuto      VersionKind = "auto"
	VersionKindDraft     VersionKind = "draft"
	VersionKindPublished VersionKind = "published"
)

// Version represents a saved version of an ebook.
type Version struct {
	ID          string      `json:"id"`
	EbookID     string      `json:"ebook_id"`
	Kind        VersionKind `json:"kind"`
	Label       string      `json:"label,omitempty"`
	S3Key       string      `json:"s3_key"`
	CreatedBy   string      `json:"created_by"`
	CreatedAt   time.Time   `json:"created_at"`
	PublishedAt *time.Time  `json:"published_at,omitempty"`
}

// ListVersionsRequest represents the request to list versions.
type ListVersionsRequest struct {
	EbookID string `json:"ebook_id"`
	Kind    string `json:"kind,omitempty"` // Optional filter: "manual" or "published"
}

// ListVersionsResponse represents the response for listing versions.
type ListVersionsResponse struct {
	Versions         []*Version `json:"versions"`
	CurrentVersionID *string    `json:"current_version_id,omitempty"`
}

// CreateVersionRequest represents the request to create a version.
type CreateVersionRequest struct {
	EbookID string `json:"ebook_id"`
	Name    string `json:"name"`
	Label   string `json:"label"`
	UserID  string `json:"user_id"`
}

// CreateVersionResponse represents the response for creating a version.
type CreateVersionResponse struct {
	Version *Version `json:"version"`
}

// PublishVersionRequest represents the request to publish a version.
type PublishVersionRequest struct {
	EbookID   string `json:"ebook_id"`
	VersionID string `json:"version_id"`
	UserID    string `json:"user_id"`
	Label     string `json:"label,omitempty"` // Optional label for the new published version
}

// PublishVersionResponse represents the response for publishing a version.
type PublishVersionResponse struct {
	Version   *Version `json:"version"`
	MediaKeys []string `json:"media_keys,omitempty"`
}

// RestoreVersionRequest represents the request to restore a version.
type RestoreVersionRequest struct {
	EbookID   string `json:"ebook_id"`
	VersionID string `json:"version_id"`
	UserID    string `json:"user_id"`
}

// RestoreVersionResponse represents the response for restoring a version.
type RestoreVersionResponse struct {
	Version         *Version        `json:"version,omitempty"`
	Content         json.RawMessage `json:"content"`
	RestoredContent json.RawMessage `json:"restored_content,omitempty"`
	RestoredAt      time.Time       `json:"restored_at"`
}

// DeleteVersionRequest represents the request to delete a version.
type DeleteVersionRequest struct {
	EbookID   string `json:"ebook_id"`
	VersionID string `json:"version_id"`
}
