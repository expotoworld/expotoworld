// Package service contains the business logic for authentication.
package service

import (
	"context"
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"fmt"
	"log/slog"
	"math/big"
	"strings"
	"time"

	"github.com/expotoworld/expotoworld_backend/services/auth/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/auth/internal/repository"
	"github.com/golang-jwt/jwt/v5"
)

// Common errors
var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrRateLimitExceeded  = errors.New("rate limit exceeded, please try again later")
	ErrInvalidCode        = errors.New("invalid or expired verification code")
	ErrMaxAttemptsReached = errors.New("maximum verification attempts reached")
	ErrUserNotFound       = errors.New("user not found")
	ErrUserBanned         = errors.New("user account is banned")
	ErrUserInactive       = errors.New("user account is inactive")
	ErrInvalidToken       = errors.New("invalid or expired token")
	ErrTokenRevoked       = errors.New("token has been revoked")
	ErrNotAdmin           = errors.New("user is not an admin")
)

// EmailSender is the interface for sending emails.
type EmailSender interface {
	SendOTPEmail(ctx context.Context, email, code string) error
}

// SMSSender is the interface for sending SMS messages.
type SMSSender interface {
	SendOTPSMS(ctx context.Context, phone, code string) error
}

// Config holds the configuration for the auth service.
type Config struct {
	JWTPrivateKey   string
	JWTIssuer       string
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration
}

// DefaultConfig returns the default configuration.
func DefaultConfig() Config {
	return Config{
		JWTIssuer:       "expotoworld", // Must match across all services validating JWTs
		AccessTokenTTL:  15 * time.Minute,
		RefreshTokenTTL: 90 * 24 * time.Hour, // 90 days
	}
}

// AuthService handles authentication business logic.
type AuthService struct {
	userRepo      repository.UserRepository
	codeRepo      repository.VerificationCodeRepository
	tokenRepo     repository.RefreshTokenRepository
	rateLimitRepo repository.RateLimitRepository
	emailSender   EmailSender
	smsSender     SMSSender
	config        Config
	privateKey    *rsa.PrivateKey
	publicKey     *rsa.PublicKey
	logger        *slog.Logger
}

// NewAuthService creates a new auth service.
func NewAuthService(
	userRepo repository.UserRepository,
	codeRepo repository.VerificationCodeRepository,
	tokenRepo repository.RefreshTokenRepository,
	rateLimitRepo repository.RateLimitRepository,
	emailSender EmailSender,
	smsSender SMSSender,
	config Config,
	logger *slog.Logger,
) (*AuthService, error) {
	// Parse RSA private key
	block, _ := pem.Decode([]byte(config.JWTPrivateKey))
	if block == nil {
		return nil, errors.New("failed to decode PEM block for private key")
	}

	privateKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		// Try PKCS1 format
		privateKey, err = x509.ParsePKCS1PrivateKey(block.Bytes)
		if err != nil {
			return nil, fmt.Errorf("failed to parse private key: %w", err)
		}
	}

	rsaPrivateKey, ok := privateKey.(*rsa.PrivateKey)
	if !ok {
		return nil, errors.New("private key is not RSA")
	}

	return &AuthService{
		userRepo:      userRepo,
		codeRepo:      codeRepo,
		tokenRepo:     tokenRepo,
		rateLimitRepo: rateLimitRepo,
		emailSender:   emailSender,
		smsSender:     smsSender,
		config:        config,
		privateKey:    rsaPrivateKey,
		publicKey:     &rsaPrivateKey.PublicKey,
		logger:        logger,
	}, nil
}

// ErrUserRoleNotPermitted is returned when user doesn't have the required role.
var ErrUserRoleNotPermitted = errors.New("user role not permitted")

// isEmail checks if the contact is an email address.
func isEmail(contact string) bool {
	return strings.Contains(contact, "@")
}

// ValidateUserAccess checks if a user exists and optionally has the required role.
// This is used by ebook-editor and similar clients that require existing users.
func (s *AuthService) ValidateUserAccess(ctx context.Context, email string, requiredRole string) error {
	user, err := s.userRepo.FindByEmail(ctx, email)
	if err != nil {
		s.logger.Error("failed to find user by email", "error", err, "email", email)
		return ErrUserNotFound
	}
	if user == nil {
		return ErrUserNotFound
	}

	if requiredRole != "" {
		// Case-insensitive role comparison
		if !strings.EqualFold(string(user.Role), requiredRole) {
			s.logger.Warn("user role not permitted", "email", email, "user_role", user.Role, "required_role", requiredRole)
			return ErrUserRoleNotPermitted
		}
	}

	return nil
}

// SendVerificationCode sends an OTP verification code to the user's email or phone.
func (s *AuthService) SendVerificationCode(ctx context.Context, contact string, actorType domain.ActorType, ipAddress string) error {
	// Determine channel type based on contact
	useEmail := isEmail(contact)
	var channelType domain.ChannelType
	var channelStr string
	if useEmail {
		channelType = domain.ChannelTypeEmail
		channelStr = "email"
	} else {
		channelType = domain.ChannelTypePhone
		channelStr = "phone"
	}

	// Rate limit check
	rateLimitConfig := domain.DefaultRateLimitConfig()
	actorTypeStr := "user"
	if actorType == domain.ActorTypeAdmin {
		actorTypeStr = "admin"
	}

	rateLimit, err := s.rateLimitRepo.GetOrCreate(ctx, actorTypeStr, channelStr, ipAddress)
	if err != nil {
		s.logger.Error("failed to get rate limit", "error", err)
		return err
	}

	if !rateLimit.CanAttempt(rateLimitConfig) {
		return ErrRateLimitExceeded
	}

	// Increment rate limit
	if err := s.rateLimitRepo.Increment(ctx, actorTypeStr, channelStr, ipAddress); err != nil {
		s.logger.Error("failed to increment rate limit", "error", err)
	}

	// For admin, verify user exists and is admin (only supported via email)
	if actorType == domain.ActorTypeAdmin {
		if !useEmail {
			return errors.New("admin login only supported via email")
		}
		user, err := s.userRepo.FindByEmail(ctx, contact)
		if err != nil {
			return err
		}
		if user == nil || !user.IsAdmin() {
			return ErrNotAdmin
		}
	}

	// Invalidate previous codes for this contact
	if err := s.codeRepo.InvalidatePreviousCodes(ctx, string(channelType), contact); err != nil {
		s.logger.Error("failed to invalidate previous codes", "error", err)
	}

	// Generate new code
	ipPtr := &ipAddress
	verificationCode, plainCode, err := domain.NewVerificationCode(contact, actorType, channelType, ipPtr)
	if err != nil {
		return fmt.Errorf("failed to generate verification code: %w", err)
	}

	// Store the code
	if err := s.codeRepo.Create(ctx, verificationCode); err != nil {
		return fmt.Errorf("failed to store verification code: %w", err)
	}

	// Send the code via appropriate channel
	if useEmail {
		if err := s.emailSender.SendOTPEmail(ctx, contact, plainCode); err != nil {
			s.logger.Error("failed to send OTP email", "error", err, "email", contact)
			return fmt.Errorf("failed to send verification code: %w", err)
		}
		s.logger.Info("verification code sent via email", "actor_type", actorType, "email", contact)
	} else {
		if s.smsSender == nil {
			return errors.New("SMS sending is not configured")
		}
		if err := s.smsSender.SendOTPSMS(ctx, contact, plainCode); err != nil {
			s.logger.Error("failed to send OTP SMS", "error", err, "phone", contact)
			return fmt.Errorf("failed to send verification code: %w", err)
		}
		s.logger.Info("verification code sent via SMS", "actor_type", actorType, "phone", contact)
	}

	return nil
}

// AuthResult contains the tokens from successful authentication.
type AuthResult struct {
	AccessToken  string
	RefreshToken string
	User         *domain.User
	IsNewUser    bool
}

// VerifyCode verifies the OTP code and returns authentication tokens.
func (s *AuthService) VerifyCode(ctx context.Context, contact, code string, actorType domain.ActorType, ipAddress, userAgent, clientDeviceID *string) (*AuthResult, error) {
	// Determine channel type based on contact
	useEmail := isEmail(contact)
	var channelType domain.ChannelType
	if useEmail {
		channelType = domain.ChannelTypeEmail
	} else {
		channelType = domain.ChannelTypePhone
	}

	// Find the latest valid code for this contact
	storedCode, err := s.codeRepo.FindLatestValid(ctx, string(channelType), contact)
	if err != nil {
		return nil, err
	}
	if storedCode == nil {
		return nil, ErrInvalidCode
	}

	// Check if code can be attempted
	if !storedCode.CanAttempt() {
		if storedCode.Attempts >= domain.MaxCodeAttempts {
			return nil, ErrMaxAttemptsReached
		}
		return nil, ErrInvalidCode
	}

	// Increment attempts
	if err := s.codeRepo.IncrementAttempts(ctx, storedCode.ID); err != nil {
		s.logger.Error("failed to increment attempts", "error", err)
	}

	// Verify the code
	if !domain.VerifyCode(code, storedCode.CodeHash) {
		return nil, ErrInvalidCode
	}

	// Mark code as used
	if err := s.codeRepo.MarkAsUsed(ctx, storedCode.ID); err != nil {
		s.logger.Error("failed to mark code as used", "error", err)
	}

	// Find user by email or phone
	var user *domain.User
	if useEmail {
		user, err = s.userRepo.FindByEmail(ctx, contact)
	} else {
		user, err = s.userRepo.FindByPhone(ctx, contact)
	}
	if err != nil {
		return nil, err
	}

	// Handle user creation or verification
	isNewUser := false
	if user == nil {
		// Create new user
		isNewUser = true
		user = &domain.User{
			Username: contact,
			Role:     domain.RoleCustomer,
			Status:   domain.StatusActive,
		}

		if useEmail {
			emailPtr := contact
			user.Email = &emailPtr
		} else {
			phonePtr := contact
			user.Phone = &phonePtr
		}

		user, err = s.userRepo.Create(ctx, user)
		if err != nil {
			return nil, fmt.Errorf("failed to create user: %w", err)
		}

		s.logger.Info("new user created", "user_id", user.ID, "contact", contact)
	}

	// Check user status
	if user.Status == domain.StatusBanned {
		return nil, ErrUserBanned
	}
	if user.Status == domain.StatusInactive {
		return nil, ErrUserInactive
	}

	// Verify admin access for admin actor type
	if actorType == domain.ActorTypeAdmin && !user.IsAdmin() {
		return nil, ErrNotAdmin
	}

	// Update last login
	if err := s.userRepo.UpdateLastLogin(ctx, user.ID); err != nil {
		s.logger.Error("failed to update last login", "error", err)
	}

	// Generate tokens
	accessToken, err := s.generateAccessToken(ctx, user)
	if err != nil {
		return nil, err
	}

	refreshToken, plainRefreshToken, err := domain.NewRefreshToken(user.ID, clientDeviceID, userAgent)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Store refresh token — also store IP/UA for audit logging
	refreshToken.IPAddress = ipAddress
	refreshToken.UserAgent = userAgent

	// Store refresh token using atomic CreateOrUpdate to prevent duplicate key violations
	// This atomically revokes any existing token for this user+device and creates the new one
	if _, err := s.tokenRepo.CreateOrUpdate(ctx, refreshToken); err != nil {
		return nil, fmt.Errorf("failed to store refresh token: %w", err)
	}

	return &AuthResult{
		AccessToken:  accessToken,
		RefreshToken: plainRefreshToken,
		User:         user,
		IsNewUser:    isNewUser,
	}, nil
}

// RefreshAccessToken refreshes the access token using a refresh token.
// Uses sliding expiry: same refresh token is reused, only expiry is extended.
// This prevents token accumulation while maintaining security.
func (s *AuthService) RefreshAccessToken(ctx context.Context, refreshToken string, ipAddress, userAgent *string) (*AuthResult, error) {
	// Hash the provided token
	tokenHash := domain.HashRefreshToken(refreshToken)

	// Find the stored token
	storedToken, err := s.tokenRepo.FindByHash(ctx, tokenHash)
	if err != nil {
		return nil, err
	}
	if storedToken == nil {
		return nil, ErrInvalidToken
	}

	// Check if valid
	if !storedToken.IsValid() {
		if storedToken.Revoked {
			return nil, ErrTokenRevoked
		}
		return nil, ErrInvalidToken
	}

	// Get the user
	user, err := s.userRepo.FindByID(ctx, storedToken.UserID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, ErrUserNotFound
	}

	// Check user status
	if user.Status == domain.StatusBanned {
		return nil, ErrUserBanned
	}
	if user.Status == domain.StatusInactive {
		return nil, ErrUserInactive
	}

	// Generate new access token
	accessToken, err := s.generateAccessToken(ctx, user)
	if err != nil {
		return nil, err
	}

	// Sliding expiry: extend the SAME refresh token's expiry instead of rotating
	// This keeps one token per device and prevents token accumulation
	newExpiry := time.Now().Add(domain.RefreshTokenTTL)
	if err := s.tokenRepo.UpdateExpiry(ctx, storedToken.ID, newExpiry, ipAddress, userAgent); err != nil {
		s.logger.Error("failed to update refresh token expiry", "error", err)
		// Non-fatal: continue even if expiry update fails
	}

	// Return the SAME refresh token (no rotation)
	// Client keeps using the same token, which has its expiry extended server-side
	return &AuthResult{
		AccessToken:  accessToken,
		RefreshToken: refreshToken, // Return same token back
		User:         user,
		IsNewUser:    false,
	}, nil
}

// Logout revokes the provided refresh token.
func (s *AuthService) Logout(ctx context.Context, refreshToken string) error {
	tokenHash := domain.HashRefreshToken(refreshToken)
	storedToken, err := s.tokenRepo.FindByHash(ctx, tokenHash)
	if err != nil {
		return err
	}
	if storedToken == nil {
		return nil // Token doesn't exist, consider it logged out
	}

	if err := s.tokenRepo.Revoke(ctx, storedToken.ID); err != nil {
		return fmt.Errorf("failed to revoke token: %w", err)
	}

	s.logger.Info("token revoked", "token_id", storedToken.ID)
	return nil
}

// generateAccessToken creates a new JWT access token.
func (s *AuthService) generateAccessToken(ctx context.Context, user *domain.User) (string, error) {
	now := time.Now()

	// Create access token claims
	accessClaims := jwt.MapClaims{
		"sub":  user.ID,
		"uid":  user.ID,
		"role": string(user.Role),
		"iss":  s.config.JWTIssuer,
		"iat":  now.Unix(),
		"exp":  now.Add(s.config.AccessTokenTTL).Unix(),
	}

	if user.Email != nil {
		accessClaims["email"] = *user.Email
	}

	if user.Phone != nil {
		accessClaims["phone"] = *user.Phone
	}

	// Note: Organization memberships are handled separately by the admin panel
	// after authentication. The auth service only handles user identity.

	// Sign access token
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, accessClaims)
	token.Header["kid"] = "primary"
	return token.SignedString(s.privateKey)
}

// GetJWKS returns the JSON Web Key Set for JWT verification.
func (s *AuthService) GetJWKS() map[string]interface{} {
	return map[string]interface{}{
		"keys": []map[string]interface{}{
			{
				"kty": "RSA",
				"use": "sig",
				"alg": "RS256",
				"kid": "primary",
				"n":   base64.RawURLEncoding.EncodeToString(s.publicKey.N.Bytes()),
				"e":   base64.RawURLEncoding.EncodeToString(big.NewInt(int64(s.publicKey.E)).Bytes()),
			},
		},
	}
}

// ValidateAccessToken validates an access token and returns the claims.
func (s *AuthService) ValidateAccessToken(tokenString string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.publicKey, nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	if !token.Valid {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, ErrInvalidToken
	}

	return claims, nil
}
