package repository

import (
	"context"

	"github.com/expotoworld/expotoworld_backend/services/auth/internal/domain"
)

// UserRepository defines the interface for user data access.
type UserRepository interface {
	// FindByID retrieves a user by their ID.
	FindByID(ctx context.Context, id string) (*domain.User, error)

	// FindByEmail retrieves a user by their email address.
	FindByEmail(ctx context.Context, email string) (*domain.User, error)

	// FindByPhone retrieves a user by their phone number.
	FindByPhone(ctx context.Context, phone string) (*domain.User, error)

	// Create creates a new user and returns the created user with ID.
	Create(ctx context.Context, user *domain.User) (*domain.User, error)

	// Update updates an existing user.
	Update(ctx context.Context, user *domain.User) error

	// UpdateLastLogin updates the user's last login timestamp.
	UpdateLastLogin(ctx context.Context, userID string) error

	// GetOrgMemberships retrieves the organization memberships for a user.
	GetOrgMemberships(ctx context.Context, userID string) ([]domain.OrgMembership, error)
}

// VerificationCodeRepository defines the interface for verification code data access.
type VerificationCodeRepository interface {
	// Create creates a new verification code.
	Create(ctx context.Context, code *domain.VerificationCode) error

	// FindLatestValid finds the latest valid (unused, unexpired) code for a subject.
	// subject is the email or phone number
	FindLatestValid(ctx context.Context, channelType string, subject string) (*domain.VerificationCode, error)

	// IncrementAttempts increments the attempt count for a verification code.
	IncrementAttempts(ctx context.Context, id string) error

	// MarkAsUsed marks a verification code as used.
	MarkAsUsed(ctx context.Context, id string) error

	// InvalidatePreviousCodes invalidates all previous unused codes for a subject.
	InvalidatePreviousCodes(ctx context.Context, channelType string, subject string) error
}

// RefreshTokenRepository defines the interface for refresh token data access.
type RefreshTokenRepository interface {
	// Create creates a new refresh token.
	Create(ctx context.Context, token *domain.RefreshToken) (string, error)

	// FindByHash retrieves a refresh token by its hash.
	FindByHash(ctx context.Context, tokenHash string) (*domain.RefreshToken, error)

	// Revoke revokes a refresh token by its ID.
	Revoke(ctx context.Context, id string) error

	// RevokeAllForUser revokes all refresh tokens for a user.
	RevokeAllForUser(ctx context.Context, userID string) error
}

// RateLimitRepository defines the interface for rate limit data access.
type RateLimitRepository interface {
	// GetOrCreate gets the current rate limit or creates a new one.
	// actorType: "admin" or "user"
	// channelType: "email" or "phone"
	// ipAddress: the client's IP address
	GetOrCreate(ctx context.Context, actorType, channelType, ipAddress string) (*domain.RateLimit, error)

	// Increment increments the request count for a rate limit.
	Increment(ctx context.Context, actorType, channelType, ipAddress string) error

	// Reset resets the rate limit for a new window.
	Reset(ctx context.Context, actorType, channelType, ipAddress string) error
}
