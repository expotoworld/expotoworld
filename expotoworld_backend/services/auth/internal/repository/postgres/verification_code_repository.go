package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/auth/internal/domain"
)

// VerificationCodeRepository is a PostgreSQL implementation of repository.VerificationCodeRepository.
type VerificationCodeRepository struct {
	pool *pgxpool.Pool
}

// NewVerificationCodeRepository creates a new PostgreSQL verification code repository.
func NewVerificationCodeRepository(pool *pgxpool.Pool) *VerificationCodeRepository {
	return &VerificationCodeRepository{pool: pool}
}

// Create creates a new verification code.
func (r *VerificationCodeRepository) Create(ctx context.Context, code *domain.VerificationCode) error {
	query := `
		INSERT INTO app_verification_codes (actor_type, channel_type, subject, code_hash, attempts, expires_at, used, ip_address, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id`

	err := r.pool.QueryRow(ctx, query,
		string(code.ActorType), string(code.ChannelType), code.Subject,
		code.CodeHash, code.Attempts, code.ExpiresAt,
		code.Used, code.IPAddress, code.CreatedAt,
	).Scan(&code.ID)
	if err != nil {
		return fmt.Errorf("failed to create verification code: %w", err)
	}

	return nil
}

// FindLatestValid finds the latest valid (unused, unexpired) code for a subject.
func (r *VerificationCodeRepository) FindLatestValid(ctx context.Context, channelType string, subject string) (*domain.VerificationCode, error) {
	query := `
		SELECT id, actor_type, channel_type, subject, code_hash, attempts, expires_at, used, ip_address, created_at
		FROM app_verification_codes
		WHERE channel_type = $1 AND subject = $2 AND used = false AND expires_at > NOW()
		ORDER BY created_at DESC
		LIMIT 1`

	var code domain.VerificationCode
	var actorType, chType string
	err := r.pool.QueryRow(ctx, query, channelType, subject).Scan(
		&code.ID, &actorType, &chType, &code.Subject,
		&code.CodeHash, &code.Attempts, &code.ExpiresAt,
		&code.Used, &code.IPAddress, &code.CreatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find latest valid code: %w", err)
	}

	code.ActorType = domain.ActorType(actorType)
	code.ChannelType = domain.ChannelType(chType)
	return &code, nil
}

// IncrementAttempts increments the attempt count for a verification code.
func (r *VerificationCodeRepository) IncrementAttempts(ctx context.Context, id string) error {
	query := `UPDATE app_verification_codes SET attempts = attempts + 1 WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to increment attempts: %w", err)
	}
	return nil
}

// MarkAsUsed marks a verification code as used.
func (r *VerificationCodeRepository) MarkAsUsed(ctx context.Context, id string) error {
	query := `UPDATE app_verification_codes SET used = true WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to mark code as used: %w", err)
	}
	return nil
}

// InvalidatePreviousCodes invalidates all previous unused codes for a subject.
func (r *VerificationCodeRepository) InvalidatePreviousCodes(ctx context.Context, channelType string, subject string) error {
	query := `UPDATE app_verification_codes SET used = true WHERE channel_type = $1 AND subject = $2 AND used = false`
	_, err := r.pool.Exec(ctx, query, channelType, subject)
	if err != nil {
		return fmt.Errorf("failed to invalidate previous codes: %w", err)
	}
	return nil
}
