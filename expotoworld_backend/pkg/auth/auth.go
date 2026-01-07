// Package auth provides JWT authentication and authorization utilities.
// It supports RS256 signing with JWKS endpoint for key distribution.
package auth

import (
	"context"
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Common errors
var (
	ErrInvalidToken      = errors.New("invalid token")
	ErrTokenExpired      = errors.New("token expired")
	ErrInvalidClaims     = errors.New("invalid claims")
	ErrMissingAuthHeader = errors.New("missing authorization header")
	ErrInvalidAuthHeader = errors.New("invalid authorization header format")
	ErrKeyNotFound       = errors.New("signing key not found")
	ErrInvalidKeyFormat  = errors.New("invalid key format")
)

// Claims represents the JWT claims structure.
type Claims struct {
	jwt.RegisteredClaims
	UserID    string   `json:"uid,omitempty"`
	Email     string   `json:"email,omitempty"`
	Role      string   `json:"role,omitempty"`
	Roles     []string `json:"roles,omitempty"`
	SessionID string   `json:"sid,omitempty"`
	TokenType string   `json:"type,omitempty"` // access, refresh
}

// Validator validates JWT tokens.
type Validator struct {
	jwksURL    string
	issuer     string
	audience   string
	publicKey  *rsa.PublicKey
	jwksCache  *jwksCache
	httpClient *http.Client
}

// ValidatorConfig holds validator configuration.
type ValidatorConfig struct {
	JWKSURL      string
	Issuer       string
	Audience     string
	PublicKeyPEM string
}

// NewValidator creates a new JWT validator.
func NewValidator(cfg ValidatorConfig) (*Validator, error) {
	v := &Validator{
		jwksURL:  cfg.JWKSURL,
		issuer:   cfg.Issuer,
		audience: cfg.Audience,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}

	// Parse public key if provided
	if cfg.PublicKeyPEM != "" {
		key, err := parseRSAPublicKey(cfg.PublicKeyPEM)
		if err != nil {
			return nil, fmt.Errorf("failed to parse public key: %w", err)
		}
		v.publicKey = key
	}

	// Initialize JWKS cache if URL provided
	if cfg.JWKSURL != "" {
		v.jwksCache = newJWKSCache(cfg.JWKSURL, v.httpClient)
	}

	return v, nil
}

// ValidateToken validates a JWT token and returns the claims.
func (v *Validator) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// Verify signing method
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}

		// Get key ID from header
		kid, _ := token.Header["kid"].(string)

		// Try JWKS first
		if v.jwksCache != nil && kid != "" {
			key, err := v.jwksCache.GetKey(kid)
			if err == nil {
				return key, nil
			}
		}

		// Fall back to static public key
		if v.publicKey != nil {
			return v.publicKey, nil
		}

		return nil, ErrKeyNotFound
	})

	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrTokenExpired
		}
		return nil, fmt.Errorf("%w: %v", ErrInvalidToken, err)
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, ErrInvalidClaims
	}

	// Validate issuer
	if v.issuer != "" && claims.Issuer != v.issuer {
		return nil, fmt.Errorf("%w: invalid issuer", ErrInvalidClaims)
	}

	// Validate audience
	if v.audience != "" {
		validAudience := false
		for _, aud := range claims.Audience {
			if aud == v.audience {
				validAudience = true
				break
			}
		}
		if !validAudience {
			return nil, fmt.Errorf("%w: invalid audience", ErrInvalidClaims)
		}
	}

	return claims, nil
}

// ExtractTokenFromHeader extracts the JWT token from an Authorization header.
func ExtractTokenFromHeader(header string) (string, error) {
	if header == "" {
		return "", ErrMissingAuthHeader
	}

	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return "", ErrInvalidAuthHeader
	}

	return strings.TrimSpace(parts[1]), nil
}

// Issuer generates and signs JWT tokens.
type Issuer struct {
	privateKey *rsa.PrivateKey
	publicKey  *rsa.PublicKey
	keyID      string
	issuer     string
	audience   string
	accessTTL  time.Duration
	refreshTTL time.Duration
}

// IssuerConfig holds issuer configuration.
type IssuerConfig struct {
	PrivateKeyPEM string
	PublicKeyPEM  string
	KeyID         string
	Issuer        string
	Audience      string
	AccessTTL     time.Duration
	RefreshTTL    time.Duration
}

// NewIssuer creates a new JWT issuer.
func NewIssuer(cfg IssuerConfig) (*Issuer, error) {
	privateKey, err := parseRSAPrivateKey(cfg.PrivateKeyPEM)
	if err != nil {
		return nil, fmt.Errorf("failed to parse private key: %w", err)
	}

	publicKey := &privateKey.PublicKey
	if cfg.PublicKeyPEM != "" {
		publicKey, err = parseRSAPublicKey(cfg.PublicKeyPEM)
		if err != nil {
			return nil, fmt.Errorf("failed to parse public key: %w", err)
		}
	}

	accessTTL := cfg.AccessTTL
	if accessTTL == 0 {
		accessTTL = 15 * time.Minute
	}

	refreshTTL := cfg.RefreshTTL
	if refreshTTL == 0 {
		refreshTTL = 7 * 24 * time.Hour
	}

	return &Issuer{
		privateKey: privateKey,
		publicKey:  publicKey,
		keyID:      cfg.KeyID,
		issuer:     cfg.Issuer,
		audience:   cfg.Audience,
		accessTTL:  accessTTL,
		refreshTTL: refreshTTL,
	}, nil
}

// TokenPair represents an access and refresh token pair.
type TokenPair struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	TokenType    string    `json:"token_type"`
	ExpiresIn    int64     `json:"expires_in"`
	ExpiresAt    time.Time `json:"expires_at"`
}

// IssueTokenPair generates both access and refresh tokens.
func (i *Issuer) IssueTokenPair(userID, email, role, sessionID string, additionalRoles []string) (*TokenPair, error) {
	now := time.Now()
	accessExpiry := now.Add(i.accessTTL)
	refreshExpiry := now.Add(i.refreshTTL)

	// Issue access token
	accessClaims := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    i.issuer,
			Subject:   userID,
			Audience:  jwt.ClaimStrings{i.audience},
			ExpiresAt: jwt.NewNumericDate(accessExpiry),
			NotBefore: jwt.NewNumericDate(now),
			IssuedAt:  jwt.NewNumericDate(now),
			ID:        generateJTI(),
		},
		UserID:    userID,
		Email:     email,
		Role:      role,
		Roles:     additionalRoles,
		SessionID: sessionID,
		TokenType: "access",
	}

	accessToken := jwt.NewWithClaims(jwt.SigningMethodRS256, accessClaims)
	if i.keyID != "" {
		accessToken.Header["kid"] = i.keyID
	}

	accessTokenString, err := accessToken.SignedString(i.privateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to sign access token: %w", err)
	}

	// Issue refresh token
	refreshClaims := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    i.issuer,
			Subject:   userID,
			Audience:  jwt.ClaimStrings{i.audience},
			ExpiresAt: jwt.NewNumericDate(refreshExpiry),
			NotBefore: jwt.NewNumericDate(now),
			IssuedAt:  jwt.NewNumericDate(now),
			ID:        generateJTI(),
		},
		UserID:    userID,
		SessionID: sessionID,
		TokenType: "refresh",
	}

	refreshToken := jwt.NewWithClaims(jwt.SigningMethodRS256, refreshClaims)
	if i.keyID != "" {
		refreshToken.Header["kid"] = i.keyID
	}

	refreshTokenString, err := refreshToken.SignedString(i.privateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to sign refresh token: %w", err)
	}

	return &TokenPair{
		AccessToken:  accessTokenString,
		RefreshToken: refreshTokenString,
		TokenType:    "Bearer",
		ExpiresIn:    int64(i.accessTTL.Seconds()),
		ExpiresAt:    accessExpiry,
	}, nil
}

// GetJWKS returns the JWKS representation of the public key.
func (i *Issuer) GetJWKS() *JWKS {
	n := base64.RawURLEncoding.EncodeToString(i.publicKey.N.Bytes())
	e := base64.RawURLEncoding.EncodeToString(big.NewInt(int64(i.publicKey.E)).Bytes())

	return &JWKS{
		Keys: []JWK{
			{
				Kty: "RSA",
				Use: "sig",
				Alg: "RS256",
				Kid: i.keyID,
				N:   n,
				E:   e,
			},
		},
	}
}

// JWKS represents a JSON Web Key Set.
type JWKS struct {
	Keys []JWK `json:"keys"`
}

// JWK represents a JSON Web Key.
type JWK struct {
	Kty string `json:"kty"`
	Use string `json:"use"`
	Alg string `json:"alg"`
	Kid string `json:"kid"`
	N   string `json:"n"`
	E   string `json:"e"`
}

// jwksCache caches JWKS keys from a remote endpoint.
type jwksCache struct {
	url       string
	client    *http.Client
	keys      map[string]*rsa.PublicKey
	mu        sync.RWMutex
	lastFetch time.Time
	cacheTTL  time.Duration
}

func newJWKSCache(url string, client *http.Client) *jwksCache {
	return &jwksCache{
		url:      url,
		client:   client,
		keys:     make(map[string]*rsa.PublicKey),
		cacheTTL: 1 * time.Hour,
	}
}

func (c *jwksCache) GetKey(kid string) (*rsa.PublicKey, error) {
	c.mu.RLock()
	key, ok := c.keys[kid]
	needsRefresh := time.Since(c.lastFetch) > c.cacheTTL
	c.mu.RUnlock()

	if ok && !needsRefresh {
		return key, nil
	}

	if err := c.refresh(); err != nil {
		if ok {
			return key, nil // Use cached key on refresh failure
		}
		return nil, err
	}

	c.mu.RLock()
	key, ok = c.keys[kid]
	c.mu.RUnlock()

	if !ok {
		return nil, ErrKeyNotFound
	}

	return key, nil
}

func (c *jwksCache) refresh() error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.url, nil)
	if err != nil {
		return err
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("JWKS endpoint returned status %d", resp.StatusCode)
	}

	var jwks JWKS
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return err
	}

	newKeys := make(map[string]*rsa.PublicKey)
	for _, jwk := range jwks.Keys {
		if jwk.Kty != "RSA" || jwk.Use != "sig" {
			continue
		}

		key, err := jwkToRSAPublicKey(jwk)
		if err != nil {
			continue
		}

		newKeys[jwk.Kid] = key
	}

	c.mu.Lock()
	c.keys = newKeys
	c.lastFetch = time.Now()
	c.mu.Unlock()

	return nil
}

func jwkToRSAPublicKey(jwk JWK) (*rsa.PublicKey, error) {
	nBytes, err := base64.RawURLEncoding.DecodeString(jwk.N)
	if err != nil {
		return nil, err
	}

	eBytes, err := base64.RawURLEncoding.DecodeString(jwk.E)
	if err != nil {
		return nil, err
	}

	n := new(big.Int).SetBytes(nBytes)
	e := int(new(big.Int).SetBytes(eBytes).Int64())

	return &rsa.PublicKey{N: n, E: e}, nil
}

func parseRSAPublicKey(pemStr string) (*rsa.PublicKey, error) {
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil {
		return nil, ErrInvalidKeyFormat
	}

	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return nil, err
	}

	rsaPub, ok := pub.(*rsa.PublicKey)
	if !ok {
		return nil, ErrInvalidKeyFormat
	}

	return rsaPub, nil
}

func parseRSAPrivateKey(pemStr string) (*rsa.PrivateKey, error) {
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil {
		return nil, ErrInvalidKeyFormat
	}

	// Try PKCS#8 first
	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err == nil {
		rsaKey, ok := key.(*rsa.PrivateKey)
		if ok {
			return rsaKey, nil
		}
	}

	// Try PKCS#1
	return x509.ParsePKCS1PrivateKey(block.Bytes)
}

func generateJTI() string {
	b := make([]byte, 16)
	// Use crypto/rand for production
	return base64.RawURLEncoding.EncodeToString(b)
}

// Context keys for auth
type contextKey string

const (
	claimsKey contextKey = "auth_claims"
)

// ContextWithClaims adds claims to the context.
func ContextWithClaims(ctx context.Context, claims *Claims) context.Context {
	return context.WithValue(ctx, claimsKey, claims)
}

// ClaimsFromContext extracts claims from the context.
func ClaimsFromContext(ctx context.Context) (*Claims, bool) {
	claims, ok := ctx.Value(claimsKey).(*Claims)
	return claims, ok
}

// GetUserIDFromContext extracts the user ID from context claims.
func GetUserIDFromContext(ctx context.Context) string {
	if claims, ok := ClaimsFromContext(ctx); ok {
		return claims.UserID
	}
	return ""
}

// GetRoleFromContext extracts the role from context claims.
func GetRoleFromContext(ctx context.Context) string {
	if claims, ok := ClaimsFromContext(ctx); ok {
		return claims.Role
	}
	return ""
}

// HasRole checks if the user has a specific role.
func HasRole(ctx context.Context, role string) bool {
	claims, ok := ClaimsFromContext(ctx)
	if !ok {
		return false
	}

	if claims.Role == role {
		return true
	}

	for _, r := range claims.Roles {
		if r == role {
			return true
		}
	}

	return false
}
