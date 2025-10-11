package models

import (
	"time"
)

// AdminVerificationCode represents a verification code for admin authentication
type AdminVerificationCode struct {
	ID        string    `json:"id" db:"id"`
	Email     string    `json:"email" db:"email"`
	CodeHash  string    `json:"-" db:"code_hash"` // Never expose code hash
	Attempts  int       `json:"attempts" db:"attempts"`
	ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
	Used      bool      `json:"used" db:"used"`
	IPAddress string    `json:"ip_address,omitempty" db:"ip_address"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// AdminRateLimit represents rate limiting for admin verification requests
type AdminRateLimit struct {
	ID           string    `json:"id" db:"id"`
	IPAddress    string    `json:"ip_address" db:"ip_address"`
	RequestCount int       `json:"request_count" db:"request_count"`
	WindowStart  time.Time `json:"window_start" db:"window_start"`
}

// SendVerificationRequest represents the request to send a verification code
type SendVerificationRequest struct {
	Email string `json:"email" binding:"required,email"`
}

// SendVerificationResponse represents the response after sending verification code
type SendVerificationResponse struct {
	Message   string    `json:"message"`
	ExpiresAt time.Time `json:"expires_at"`
}

// VerifyCodeRequest represents the request to verify a code
type VerifyCodeRequest struct {
	Email string `json:"email" binding:"required,email"`
	Code  string `json:"code" binding:"required,len=6"`
}

// VerifyCodeResponse represents the response after successful verification
type VerifyCodeResponse struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
	User      AdminUser `json:"user"`
}

// AdminUser represents an admin user for email-based authentication
type AdminUser struct {
	Email     string    `json:"email"`
	Role      string    `json:"role"`
	CreatedAt time.Time `json:"created_at"`
}

// EmailVerificationData represents data for email template
type EmailVerificationData struct {
	Code         string
	Email        string
	ExpiresAt    time.Time
	IPAddress    string
	UserAgent    string
	Timestamp    time.Time
	ExpiresInMin int
}
