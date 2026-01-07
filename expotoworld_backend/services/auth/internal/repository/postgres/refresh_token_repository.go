package postgres

import (
	"context"
	"fmt"

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
		INSERT INTO app_refresh_tokens (user_id, token_hash, issued_at, expires_at, revoked, ip_address, user_agent)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id`

	err := r.pool.QueryRow(ctx, query,
		token.UserID, token.TokenHash, token.IssuedAt, token.ExpiresAt,
		token.Revoked, token.IPAddress, token.UserAgent,
	).Scan(&token.ID)
	if err != nil {
		return "", fmt.Errorf("failed to create refresh token: %w", err)
	}

	return token.ID, nil
}

// FindByHash retrieves a refresh token by its hash.
func (r *RefreshTokenRepository) FindByHash(ctx context.Context, tokenHash string) (*domain.RefreshToken, error) {
	query := `
		SELECT id, user_id, token_hash, issued_at, expires_at, revoked, ip_address, user_agent
		FROM app_refresh_tokens
		WHERE token_hash = $1`

	var token domain.RefreshToken
	err := r.pool.QueryRow(ctx, query, tokenHash).Scan(
		&token.ID, &token.UserID, &token.TokenHash, &token.IssuedAt,
		&token.ExpiresAt, &token.Revoked, &token.IPAddress, &token.UserAgent,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find refresh token by hash: %w", err)
	}

	return &token, nil
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
