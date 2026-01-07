package domain

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"math/big"
	"time"
)

// ActorType represents who is performing authentication.
type ActorType string

const (
	ActorTypeUser  ActorType = "user"
	ActorTypeAdmin ActorType = "admin"
)

// ChannelType represents the communication channel.
type ChannelType string

const (
	ChannelTypeEmail ChannelType = "email"
	ChannelTypePhone ChannelType = "phone"
)

// CodeTTL is the duration a verification code is valid (10 minutes).
const CodeTTL = 10 * time.Minute

// MaxCodeAttempts is the maximum number of verification attempts allowed.
const MaxCodeAttempts = 5

// VerificationCode represents an OTP verification code.
type VerificationCode struct {
	ID          string
	ActorType   ActorType   // Who requested the code (admin/user)
	ChannelType ChannelType // Communication channel (email/phone)
	Subject     string      // The email or phone number
	CodeHash    string      // SHA-256 hash of the 6-digit code
	Attempts    int         // Number of failed verification attempts
	ExpiresAt   time.Time
	Used        bool // Whether the code has been used
	IPAddress   *string
	CreatedAt   time.Time
}

// IsExpired returns true if the verification code has expired.
func (v *VerificationCode) IsExpired() bool {
	return time.Now().After(v.ExpiresAt)
}

// IsUsed returns true if the verification code has been used.
func (v *VerificationCode) IsUsed() bool {
	return v.Used
}

// CanAttempt returns true if more verification attempts are allowed.
func (v *VerificationCode) CanAttempt() bool {
	return v.Attempts < MaxCodeAttempts && !v.IsExpired() && !v.IsUsed()
}

// RemainingAttempts returns the number of remaining verification attempts.
func (v *VerificationCode) RemainingAttempts() int {
	remaining := MaxCodeAttempts - v.Attempts
	if remaining < 0 {
		return 0
	}
	return remaining
}

// Generate6DigitCode generates a cryptographically secure 6-digit OTP code.
func Generate6DigitCode() (string, error) {
	max := big.NewInt(1000000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", fmt.Errorf("failed to generate random number: %w", err)
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

// HashCode creates a SHA-256 hash of a verification code.
func HashCode(code string) string {
	hash := sha256.Sum256([]byte(code))
	return base64.RawURLEncoding.EncodeToString(hash[:])
}

// VerifyCode compares a plain code against a hash.
func VerifyCode(plainCode, hashedCode string) bool {
	return HashCode(plainCode) == hashedCode
}

// NewVerificationCode creates a new verification code entity.
func NewVerificationCode(subject string, actorType ActorType, channelType ChannelType, ipAddress *string) (*VerificationCode, string, error) {
	plainCode, err := Generate6DigitCode()
	if err != nil {
		return nil, "", err
	}

	codeHash := HashCode(plainCode)
	now := time.Now()

	return &VerificationCode{
		ActorType:   actorType,
		ChannelType: channelType,
		Subject:     subject,
		CodeHash:    codeHash,
		Attempts:    0,
		ExpiresAt:   now.Add(CodeTTL),
		Used:        false,
		IPAddress:   ipAddress,
		CreatedAt:   now,
	}, plainCode, nil
}
