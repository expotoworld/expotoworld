// Package domain contains the business entities for the ebook service.
package domain

import (
	"encoding/json"
	"time"
)

// Ebook represents the main ebook entity.
// Matches the existing database schema.
type Ebook struct {
	ID        string          `json:"id"`
	Slug      string          `json:"slug"`
	Title     *string         `json:"title,omitempty"`
	Content   json.RawMessage `json:"content,omitempty"`
	CreatedAt time.Time       `json:"created_at"`
	UpdatedAt time.Time       `json:"updated_at"`
}

// GetDraftResponse represents the response for getting draft content.
type GetDraftResponse struct {
	EbookID    string          `json:"ebook_id"`
	Slug       string          `json:"slug"`
	Title      *string         `json:"title,omitempty"`
	Content    json.RawMessage `json:"content,omitempty"`
	CDNBaseURL string          `json:"cdn_base_url"`
}

// SaveDraftRequest represents the request body for saving draft content.
type SaveDraftRequest struct {
	EbookID string          `json:"ebook_id"`
	UserID  string          `json:"user_id"`
	Content json.RawMessage `json:"content"`
}

// SaveDraftResponse represents the response for saving draft content.
type SaveDraftResponse struct {
	Success   bool      `json:"success"`
	SavedAt   time.Time `json:"saved_at"`
	MediaKeys []string  `json:"media_keys,omitempty"`
}
