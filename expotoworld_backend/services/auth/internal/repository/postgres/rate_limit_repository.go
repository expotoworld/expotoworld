package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/auth/internal/domain"
)

// RateLimitRepository is a PostgreSQL implementation of repository.RateLimitRepository.
type RateLimitRepository struct {
	pool *pgxpool.Pool
}

// NewRateLimitRepository creates a new PostgreSQL rate limit repository.
func NewRateLimitRepository(pool *pgxpool.Pool) *RateLimitRepository {
	return &RateLimitRepository{pool: pool}
}

// GetOrCreate gets the current rate limit or creates a new one.
// actorType: "admin" or "user"
// channelType: "email" or "phone"
// ipAddress: the client's IP address
// Returns the current rate limit state. Call Increment separately to record a request.
func (r *RateLimitRepository) GetOrCreate(ctx context.Context, actorType, channelType, ipAddress string) (*domain.RateLimit, error) {
	// First try to get existing rate limit
	rateLimit, err := r.get(ctx, actorType, channelType, ipAddress)
	if err != nil {
		return nil, err
	}
	if rateLimit != nil {
		// Check if window has expired and reset if needed
		config := domain.DefaultRateLimitConfig()
		if rateLimit.IsWindowExpired(config.WindowSize) {
			if err := r.Reset(ctx, actorType, channelType, ipAddress); err != nil {
				return nil, err
			}
			// Return fresh rate limit with count=0 (will be incremented separately)
			return &domain.RateLimit{
				ActorType:    actorType,
				ChannelType:  channelType,
				IPAddress:    ipAddress,
				RequestCount: 0,
				WindowStart:  time.Now(),
			}, nil
		}
		return rateLimit, nil
	}

	// Create new rate limit with count=0 (will be incremented separately)
	query := `
		INSERT INTO app_rate_limits (actor_type, channel_type, ip_address, request_count, window_start)
		VALUES ($1, $2, $3, 0, NOW())
		RETURNING id, window_start`

	var id string
	var windowStart time.Time
	err = r.pool.QueryRow(ctx, query, actorType, channelType, ipAddress).Scan(&id, &windowStart)
	if err != nil {
		return nil, fmt.Errorf("failed to create rate limit: %w", err)
	}

	return &domain.RateLimit{
		ID:           id,
		ActorType:    actorType,
		ChannelType:  channelType,
		IPAddress:    ipAddress,
		RequestCount: 0,
		WindowStart:  windowStart,
	}, nil
}

// get retrieves an existing rate limit.
func (r *RateLimitRepository) get(ctx context.Context, actorType, channelType, ipAddress string) (*domain.RateLimit, error) {
	query := `
		SELECT id, actor_type, channel_type, ip_address, request_count, window_start
		FROM app_rate_limits
		WHERE actor_type = $1 AND channel_type = $2 AND ip_address = $3`

	var rateLimit domain.RateLimit
	err := r.pool.QueryRow(ctx, query, actorType, channelType, ipAddress).Scan(
		&rateLimit.ID, &rateLimit.ActorType, &rateLimit.ChannelType,
		&rateLimit.IPAddress, &rateLimit.RequestCount, &rateLimit.WindowStart,
	)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get rate limit: %w", err)
	}

	return &rateLimit, nil
}

// Increment increments the request count for a rate limit.
func (r *RateLimitRepository) Increment(ctx context.Context, actorType, channelType, ipAddress string) error {
	query := `
		UPDATE app_rate_limits 
		SET request_count = request_count + 1
		WHERE actor_type = $1 AND channel_type = $2 AND ip_address = $3`

	_, err := r.pool.Exec(ctx, query, actorType, channelType, ipAddress)
	if err != nil {
		return fmt.Errorf("failed to increment rate limit: %w", err)
	}
	return nil
}

// Reset resets the rate limit for a new window (count=0).
func (r *RateLimitRepository) Reset(ctx context.Context, actorType, channelType, ipAddress string) error {
	query := `
		UPDATE app_rate_limits 
		SET request_count = 0, window_start = NOW()
		WHERE actor_type = $1 AND channel_type = $2 AND ip_address = $3`

	_, err := r.pool.Exec(ctx, query, actorType, channelType, ipAddress)
	if err != nil {
		return fmt.Errorf("failed to reset rate limit: %w", err)
	}
	return nil
}
