package domain

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"time"
)

// RefreshTokenTTL is the duration a refresh token is valid (90 days).
const RefreshTokenTTL = 90 * 24 * time.Hour

// AccessTokenTTL is the duration an access token is valid (15 minutes).
const AccessTokenTTL = 15 * time.Minute

// RefreshToken represents a refresh token for session management.
type RefreshToken struct {
	ID                string
	UserID            string
	TokenHash         string
	IssuedAt          time.Time
	ExpiresAt         time.Time
	Revoked           bool
	IPAddress         *string
	UserAgent         *string
	DeviceFingerprint *string // Hash of device identifiers for per-device token tracking
}

// IsExpired returns true if the refresh token has expired.
func (r *RefreshToken) IsExpired() bool {
	return time.Now().After(r.ExpiresAt)
}

// IsValid returns true if the refresh token can be used.
func (r *RefreshToken) IsValid() bool {
	return !r.Revoked && !r.IsExpired()
}

// GenerateRefreshToken generates a cryptographically secure refresh token.
// Returns the plain token (to send to client) and its hash (to store in DB).
func GenerateRefreshToken() (plainToken string, tokenHash string, err error) {
	// Generate 32 random bytes
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", "", fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Encode as URL-safe base64
	plainToken = base64.RawURLEncoding.EncodeToString(b)

	// Hash for storage
	tokenHash = HashRefreshToken(plainToken)

	return plainToken, tokenHash, nil
}

// HashRefreshToken creates a SHA-256 hash of a refresh token.
func HashRefreshToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return base64.RawURLEncoding.EncodeToString(hash[:])
}

// GenerateDeviceFingerprint creates a stable fingerprint for device identification.
// Priority order:
//  1. Client-provided device ID (most stable — persists across network changes)
//  2. User-Agent only (stable across IP changes, common per browser+OS)
//  3. nil if nothing available
//
// IP address is intentionally excluded because it changes frequently (mobile networks,
// VPN toggling, ISP rotation), causing orphan tokens and unnecessary re-authentication.
func GenerateDeviceFingerprint(clientDeviceID *string, userAgent *string) *string {
	// Prefer client-generated persistent device ID (stored in localStorage/cookie)
	if clientDeviceID != nil && *clientDeviceID != "" {
		hash := sha256.Sum256([]byte("device:" + *clientDeviceID))
		fingerprint := base64.RawURLEncoding.EncodeToString(hash[:16])
		return &fingerprint
	}

	// Fallback: User-Agent only (no IP — too volatile)
	if userAgent != nil && *userAgent != "" {
		hash := sha256.Sum256([]byte("ua:" + *userAgent))
		fingerprint := base64.RawURLEncoding.EncodeToString(hash[:16])
		return &fingerprint
	}

	return nil
}

// NewRefreshToken creates a new refresh token entity.
// clientDeviceID is a persistent identifier sent by web clients (preferred for fingerprinting).
func NewRefreshToken(userID string, clientDeviceID, userAgent *string) (*RefreshToken, string, error) {
	plainToken, tokenHash, err := GenerateRefreshToken()
	if err != nil {
		return nil, "", err
	}

	now := time.Now()
	fingerprint := GenerateDeviceFingerprint(clientDeviceID, userAgent)

	return &RefreshToken{
		UserID:            userID,
		TokenHash:         tokenHash,
		IssuedAt:          now,
		ExpiresAt:         now.Add(RefreshTokenTTL),
		Revoked:           false,
		UserAgent:         userAgent,
		DeviceFingerprint: fingerprint,
	}, plainToken, nil
}
