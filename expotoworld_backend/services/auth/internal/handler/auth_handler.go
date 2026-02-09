package handler

import (
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/expotoworld/expotoworld_backend/services/auth/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/auth/internal/service"
)

const (
	// refreshTokenCookieName is the httpOnly cookie name for the refresh token.
	// Using __Host- prefix enforces Secure + no Domain + Path=/ (strongest cookie security).
	refreshTokenCookieName = "__etw_rt"

	// cookiePath restricts the cookie to auth endpoints only.
	cookiePath = "/api/v1/auth"
)

// AuthHandler handles HTTP requests for authentication.
type AuthHandler struct {
	authService *service.AuthService
	logger      *slog.Logger
}

// NewAuthHandler creates a new auth handler.
func NewAuthHandler(authService *service.AuthService, logger *slog.Logger) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		logger:      logger,
	}
}

// RegisterRoutes registers auth routes with the Gin router.
func (h *AuthHandler) RegisterRoutes(r *gin.Engine) {
	api := r.Group("/api/v1/auth")
	{
		api.POST("/send-code", h.SendCode)
		api.POST("/verify-code", h.VerifyCode)
		api.POST("/refresh", h.RefreshToken)
		api.POST("/logout", h.Logout)
	}

	// Admin routes
	admin := r.Group("/api/v1/admin/auth")
	{
		admin.POST("/send-code", h.AdminSendCode)
		admin.POST("/verify-code", h.AdminVerifyCode)
	}

	// JWKS endpoint
	r.GET("/.well-known/jwks.json", h.JWKS)
}

// SendCodeRequest is the request body for sending a verification code.
// Either email or phone must be provided, but not both.
type SendCodeRequest struct {
	Email string `json:"email" binding:"omitempty,email"`
	Phone string `json:"phone" binding:"omitempty,e164"`
}

// SendCodeResponse is the response for sending a verification code.
type SendCodeResponse struct {
	Message string `json:"message"`
}

// SendCode handles POST /api/v1/auth/send-code
func (h *AuthHandler) SendCode(c *gin.Context) {
	var req SendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
		return
	}

	// Validate that exactly one of email or phone is provided
	hasEmail := req.Email != ""
	hasPhone := req.Phone != ""

	if !hasEmail && !hasPhone {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email or phone number is required"})
		return
	}
	if hasEmail && hasPhone {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Provide either email or phone, not both"})
		return
	}

	var contact string
	if hasEmail {
		contact = req.Email
	} else {
		contact = req.Phone
	}

	// Optional stricter mode for clients like ebook-editor
	// X-Require-Existing: true - requires user to already exist in database
	// X-Require-Role: Author - requires user to have specific role
	requireExisting := strings.EqualFold(c.GetHeader("X-Require-Existing"), "true") || c.Query("require_existing") == "true"
	requiredRole := strings.TrimSpace(c.GetHeader("X-Require-Role"))

	if requireExisting || requiredRole != "" {
		// Only email validation is supported for role checks
		if !hasEmail {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email is required when X-Require-Existing or X-Require-Role is set"})
			return
		}

		if err := h.authService.ValidateUserAccess(c.Request.Context(), req.Email, requiredRole); err != nil {
			h.logger.Warn("user access validation failed", "email", req.Email, "require_existing", requireExisting, "required_role", requiredRole, "error", err)
			if strings.Contains(err.Error(), "not found") {
				c.JSON(http.StatusForbidden, gin.H{"error": "User not allowed", "message": "User does not exist"})
				return
			}
			if strings.Contains(err.Error(), "not permitted") {
				c.JSON(http.StatusForbidden, gin.H{"error": "User not allowed", "message": "User role not permitted"})
				return
			}
			c.JSON(http.StatusForbidden, gin.H{"error": "User not allowed", "message": err.Error()})
			return
		}
	}

	ipAddress := c.ClientIP()
	err := h.authService.SendVerificationCode(c.Request.Context(), contact, domain.ActorTypeUser, ipAddress)
	if err != nil {
		h.logger.Error("failed to send verification code", "error", err, "contact", contact)
		if strings.Contains(err.Error(), "rate limit") {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send verification code"})
		return
	}

	c.JSON(http.StatusOK, SendCodeResponse{Message: "Verification code sent"})
}

// VerifyCodeRequest is the request body for verifying a code.
// Either email or phone must be provided, but not both.
type VerifyCodeRequest struct {
	Email string `json:"email" binding:"omitempty,email"`
	Phone string `json:"phone" binding:"omitempty,e164"`
	Code  string `json:"code" binding:"required,len=6"`
}

// VerifyCodeResponse is the response for successful verification.
type VerifyCodeResponse struct {
	AccessToken      string `json:"access_token"`
	RefreshToken     string `json:"refresh_token"`
	TokenType        string `json:"token_type"`
	ExpiresIn        int    `json:"expires_in"`
	RefreshExpiresIn int    `json:"refresh_expires_in"`
	RefreshExpiresAt string `json:"refresh_expires_at"`
}

// setRefreshTokenCookie sets an httpOnly secure cookie for the refresh token.
// This provides dual-storage redundancy: cookie + client-side localStorage.
func setRefreshTokenCookie(c *gin.Context, token string, maxAge time.Duration) {
	c.SetSameSite(http.SameSiteLaxMode)
	c.SetCookie(
		refreshTokenCookieName,
		token,
		int(maxAge.Seconds()),
		cookiePath,
		"",    // empty domain = exact host match (most secure)
		true,  // Secure: HTTPS only
		true,  // HttpOnly: inaccessible to JavaScript
	)
}

// clearRefreshTokenCookie removes the refresh token cookie on logout.
func clearRefreshTokenCookie(c *gin.Context) {
	c.SetSameSite(http.SameSiteLaxMode)
	c.SetCookie(
		refreshTokenCookieName,
		"",
		-1, // Max-Age=-1 → browser deletes immediately
		cookiePath,
		"",
		true,
		true,
	)
}

// getDeviceID extracts the client-provided device identifier from the request header.
func getDeviceID(c *gin.Context) *string {
	id := strings.TrimSpace(c.GetHeader("X-Device-Id"))
	if id == "" {
		return nil
	}
	return &id
}

// buildVerifyCodeResponse builds the standard auth response with refresh token metadata.
func buildVerifyCodeResponse(accessToken, refreshToken string) VerifyCodeResponse {
	refreshExpiresAt := time.Now().Add(domain.RefreshTokenTTL)
	return VerifyCodeResponse{
		AccessToken:      accessToken,
		RefreshToken:     refreshToken,
		TokenType:        "Bearer",
		ExpiresIn:        int(domain.AccessTokenTTL.Seconds()),
		RefreshExpiresIn: int(domain.RefreshTokenTTL.Seconds()),
		RefreshExpiresAt: refreshExpiresAt.Format(time.RFC3339),
	}
}

// VerifyCode handles POST /api/v1/auth/verify-code
func (h *AuthHandler) VerifyCode(c *gin.Context) {
	var req VerifyCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	// Validate that exactly one of email or phone is provided
	hasEmail := req.Email != ""
	hasPhone := req.Phone != ""

	if !hasEmail && !hasPhone {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email or phone number is required"})
		return
	}
	if hasEmail && hasPhone {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Provide either email or phone, not both"})
		return
	}

	var contact string
	if hasEmail {
		contact = req.Email
	} else {
		contact = req.Phone
	}

	ipAddress := c.ClientIP()
	userAgent := c.Request.UserAgent()
	deviceID := getDeviceID(c)

	result, err := h.authService.VerifyCode(c.Request.Context(), contact, req.Code, domain.ActorTypeUser, &ipAddress, &userAgent, deviceID)
	if err != nil {
		h.logger.Error("verification failed", "error", err, "contact", contact)
		if strings.Contains(err.Error(), "invalid") || strings.Contains(err.Error(), "expired") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}
		if strings.Contains(err.Error(), "attempts") {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Verification failed"})
		return
	}

	// Set httpOnly cookie for dual-storage persistence (cookie + localStorage)
	setRefreshTokenCookie(c, result.RefreshToken, domain.RefreshTokenTTL)
	c.JSON(http.StatusOK, buildVerifyCodeResponse(result.AccessToken, result.RefreshToken))
}

// RefreshTokenRequest is the request body for refreshing tokens.
// RefreshToken is optional in the body when it's sent via httpOnly cookie.
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token"`
}

// RefreshToken handles POST /api/v1/auth/refresh
// Accepts the refresh token from:
//  1. JSON body (backward compatible with mobile clients and localStorage fallback)
//  2. httpOnly cookie (primary for web clients with cookie support)
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	_ = c.ShouldBindJSON(&req) // non-fatal: body may be empty when using cookie

	// Resolve refresh token: body first (explicit), then cookie (implicit)
	refreshToken := strings.TrimSpace(req.RefreshToken)
	if refreshToken == "" {
		if cookie, err := c.Cookie(refreshTokenCookieName); err == nil && cookie != "" {
			refreshToken = cookie
		}
	}
	if refreshToken == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Refresh token required (body or cookie)"})
		return
	}

	ipAddress := c.ClientIP()
	userAgent := c.Request.UserAgent()

	result, err := h.authService.RefreshAccessToken(c.Request.Context(), refreshToken, &ipAddress, &userAgent)
	if err != nil {
		h.logger.Error("token refresh failed", "error", err)
		if strings.Contains(err.Error(), "invalid") || strings.Contains(err.Error(), "expired") || strings.Contains(err.Error(), "revoked") {
			// Clear stale cookie on auth failure
			clearRefreshTokenCookie(c)
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to refresh token"})
		return
	}

	// Re-set the httpOnly cookie with extended sliding expiry
	setRefreshTokenCookie(c, result.RefreshToken, domain.RefreshTokenTTL)
	c.JSON(http.StatusOK, buildVerifyCodeResponse(result.AccessToken, result.RefreshToken))
}

// LogoutRequest is the request body for logout.
// RefreshToken is optional in body when using httpOnly cookie.
type LogoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

// Logout handles POST /api/v1/auth/logout
// Accepts refresh token from body or cookie for revocation.
func (h *AuthHandler) Logout(c *gin.Context) {
	var req LogoutRequest
	_ = c.ShouldBindJSON(&req) // non-fatal: body may be empty when using cookie

	// Resolve refresh token: body first, then cookie
	refreshToken := strings.TrimSpace(req.RefreshToken)
	if refreshToken == "" {
		if cookie, err := c.Cookie(refreshTokenCookieName); err == nil && cookie != "" {
			refreshToken = cookie
		}
	}

	if refreshToken != "" {
		if err := h.authService.Logout(c.Request.Context(), refreshToken); err != nil {
			h.logger.Error("logout failed", "error", err)
		}
	}

	// Always clear the cookie regardless of server-side outcome
	clearRefreshTokenCookie(c)
	c.JSON(http.StatusOK, gin.H{"message": "Logged out"})
}

// AdminSendCode handles POST /api/v1/admin/auth/send-code
func (h *AuthHandler) AdminSendCode(c *gin.Context) {
	var req SendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid email address"})
		return
	}

	ipAddress := c.ClientIP()
	err := h.authService.SendVerificationCode(c.Request.Context(), req.Email, domain.ActorTypeAdmin, ipAddress)
	if err != nil {
		h.logger.Error("failed to send admin verification code", "error", err, "email", req.Email)
		if strings.Contains(err.Error(), "rate limit") {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error()})
			return
		}
		if strings.Contains(err.Error(), "not an admin") {
			c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send verification code"})
		return
	}

	c.JSON(http.StatusOK, SendCodeResponse{Message: "Verification code sent"})
}

// AdminVerifyCode handles POST /api/v1/admin/auth/verify-code
func (h *AuthHandler) AdminVerifyCode(c *gin.Context) {
	var req VerifyCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	ipAddress := c.ClientIP()
	userAgent := c.Request.UserAgent()
	deviceID := getDeviceID(c)

	result, err := h.authService.VerifyCode(c.Request.Context(), req.Email, req.Code, domain.ActorTypeAdmin, &ipAddress, &userAgent, deviceID)
	if err != nil {
		h.logger.Error("admin verification failed", "error", err, "email", req.Email)
		if strings.Contains(err.Error(), "invalid") || strings.Contains(err.Error(), "expired") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}
		if strings.Contains(err.Error(), "attempts") {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Verification failed"})
		return
	}

	setRefreshTokenCookie(c, result.RefreshToken, domain.RefreshTokenTTL)
	c.JSON(http.StatusOK, buildVerifyCodeResponse(result.AccessToken, result.RefreshToken))
}

// JWKS handles GET /.well-known/jwks.json
func (h *AuthHandler) JWKS(c *gin.Context) {
	jwks := h.authService.GetJWKS()
	c.JSON(http.StatusOK, jwks)
}
