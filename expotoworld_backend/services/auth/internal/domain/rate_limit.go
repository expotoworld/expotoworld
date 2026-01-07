package domain

import (
	"time"
)

// RateLimit represents a rate limit record for auth attempts
type RateLimit struct {
	ID           string    `json:"id"`
	ActorType    string    `json:"actor_type"`    // "admin" or "user"
	ChannelType  string    `json:"channel_type"`  // "email" or "phone"
	IPAddress    string    `json:"ip_address"`
	RequestCount int       `json:"request_count"`
	WindowStart  time.Time `json:"window_start"`
}

// RateLimitConfig holds rate limiting configuration
type RateLimitConfig struct {
	MaxAttempts   int           // Maximum attempts allowed in window
	WindowSize    time.Duration // Time window for rate limiting
}

// DefaultRateLimitConfig returns the default rate limit configuration
// 5 attempts per 15-minute window
func DefaultRateLimitConfig() RateLimitConfig {
	return RateLimitConfig{
		MaxAttempts: 5,
		WindowSize:  15 * time.Minute,
	}
}

// IsWindowExpired checks if the rate limit window has expired
func (r *RateLimit) IsWindowExpired(windowSize time.Duration) bool {
	return time.Now().After(r.WindowStart.Add(windowSize))
}

// CanAttempt checks if another attempt is allowed
func (r *RateLimit) CanAttempt(config RateLimitConfig) bool {
	// If window expired, reset is needed, so allow
	if r.IsWindowExpired(config.WindowSize) {
		return true
	}
	return r.RequestCount < config.MaxAttempts
}

// RemainingAttempts returns the number of remaining attempts
func (r *RateLimit) RemainingAttempts(config RateLimitConfig) int {
	if r.IsWindowExpired(config.WindowSize) {
		return config.MaxAttempts
	}
	remaining := config.MaxAttempts - r.RequestCount
	if remaining < 0 {
		return 0
	}
	return remaining
}

// TimeUntilReset returns the duration until the rate limit window resets
func (r *RateLimit) TimeUntilReset(windowSize time.Duration) time.Duration {
	resetTime := r.WindowStart.Add(windowSize)
	if time.Now().After(resetTime) {
		return 0
	}
	return time.Until(resetTime)
}
