package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/auth/internal/domain"
)

// RefreshTokenRepository is a PostgreSQL implementation of repository.RefreshTokenRepository.
type RefreshTokenRepository struct {
	pool *pgxpool.Pool
}

// NewRefreshTokenRepository creates a new PostgreSQL refresh token repository.
func NewRefreshTokenRepository(pool *pgxpool.Pool) *RefreshTokenRepository {
	return &RefreshTokenRepository{pool: pool}
}

// Create creates a new refresh token.
func (r *RefreshTokenRepository) Create(ctx context.Context, token *domain.RefreshToken) (string, error) {
	query := `
		INSERT INTO app_refresh_tokens (user_id, token_hash, issued_at, expires_at, revoked, ip_address, user_agent, device_fingerprint)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id`

	err := r.pool.QueryRow(ctx, query,
		token.UserID, token.TokenHash, token.IssuedAt, token.ExpiresAt,
		token.Revoked, token.IPAddress, token.UserAgent, token.DeviceFingerprint,
	).Scan(&token.ID)
	if err != nil {
		return "", fmt.Errorf("failed to create refresh token: %w", err)
	}

	return token.ID, nil
}

// FindByHash retrieves a refresh token by its hash.
func (r *RefreshTokenRepository) FindByHash(ctx context.Context, tokenHash string) (*domain.RefreshToken, error) {
	query := `
		SELECT id, user_id, token_hash, issued_at, expires_at, revoked, ip_address, user_agent, device_fingerprint
		FROM app_refresh_tokens
		WHERE token_hash = $1`

	var token domain.RefreshToken
	err := r.pool.QueryRow(ctx, query, tokenHash).Scan(
		&token.ID, &token.UserID, &token.TokenHash, &token.IssuedAt,
		&token.ExpiresAt, &token.Revoked, &token.IPAddress, &token.UserAgent, &token.DeviceFingerprint,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find refresh token by hash: %w", err)
	}

	return &token, nil
}

// FindByUserAndDevice retrieves a refresh token by user ID and device fingerprint.
func (r *RefreshTokenRepository) FindByUserAndDevice(ctx context.Context, userID string, deviceFingerprint *string) (*domain.RefreshToken, error) {
	if deviceFingerprint == nil {
		return nil, nil // No device fingerprint, can't find by device
	}

	query := `
		SELECT id, user_id, token_hash, issued_at, expires_at, revoked, ip_address, user_agent, device_fingerprint
		FROM app_refresh_tokens
		WHERE user_id = $1 AND device_fingerprint = $2 AND revoked = false`

	var token domain.RefreshToken
	err := r.pool.QueryRow(ctx, query, userID, *deviceFingerprint).Scan(
		&token.ID, &token.UserID, &token.TokenHash, &token.IssuedAt,
		&token.ExpiresAt, &token.Revoked, &token.IPAddress, &token.UserAgent, &token.DeviceFingerprint,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find refresh token by user and device: %w", err)
	}

	return &token, nil
}

// UpdateExpiry extends the expiration time of a refresh token (sliding window).
func (r *RefreshTokenRepository) UpdateExpiry(ctx context.Context, id string, newExpiry time.Time, ipAddress, userAgent *string) error {
	query := `UPDATE app_refresh_tokens SET expires_at = $1, ip_address = $2, user_agent = $3 WHERE id = $4 AND revoked = false`
	_, err := r.pool.Exec(ctx, query, newExpiry, ipAddress, userAgent, id)
	if err != nil {
		return fmt.Errorf("failed to update refresh token expiry: %w", err)
	}
	return nil
}

// Revoke revokes a refresh token by its ID.
func (r *RefreshTokenRepository) Revoke(ctx context.Context, id string) error {
	query := `UPDATE app_refresh_tokens SET revoked = true WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to revoke refresh token: %w", err)
	}
	return nil
}

// RevokeAllForUser revokes all refresh tokens for a user.
func (r *RefreshTokenRepository) RevokeAllForUser(ctx context.Context, userID string) error {
	query := `UPDATE app_refresh_tokens SET revoked = true WHERE user_id = $1`
	_, err := r.pool.Exec(ctx, query, userID)
	if err != nil {
		return fmt.Errorf("failed to revoke all refresh tokens for user: %w", err)
	}
	return nil
}
