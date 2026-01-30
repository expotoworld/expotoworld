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
// Uses IP address and user agent to identify unique devices.
func GenerateDeviceFingerprint(ipAddress, userAgent *string) *string {
	if ipAddress == nil && userAgent == nil {
		return nil
	}

	// Combine IP and user-agent for fingerprint
	// Use first part of IP (subnet) for stability when IP changes slightly
	data := ""
	if ipAddress != nil {
		data += *ipAddress
	}
	if userAgent != nil {
		data += "|" + *userAgent
	}

	hash := sha256.Sum256([]byte(data))
	fingerprint := base64.RawURLEncoding.EncodeToString(hash[:16]) // Use first 16 bytes for shorter fingerprint
	return &fingerprint
}

// NewRefreshToken creates a new refresh token entity.
func NewRefreshToken(userID string, ipAddress, userAgent *string) (*RefreshToken, string, error) {
	plainToken, tokenHash, err := GenerateRefreshToken()
	if err != nil {
		return nil, "", err
	}

	now := time.Now()
	fingerprint := GenerateDeviceFingerprint(ipAddress, userAgent)

	return &RefreshToken{
		UserID:            userID,
		TokenHash:         tokenHash,
		IssuedAt:          now,
		ExpiresAt:         now.Add(RefreshTokenTTL),
		Revoked:           false,
		IPAddress:         ipAddress,
		UserAgent:         userAgent,
		DeviceFingerprint: fingerprint,
	}, plainToken, nil
}
