package handler

import (
	"log/slog"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/expotoworld/expotoworld_backend/services/auth/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/auth/internal/service"
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
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int    `json:"expires_in"`
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

	result, err := h.authService.VerifyCode(c.Request.Context(), contact, req.Code, domain.ActorTypeUser, &ipAddress, &userAgent)
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

	c.JSON(http.StatusOK, VerifyCodeResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    int(domain.AccessTokenTTL.Seconds()),
	})
}

// RefreshTokenRequest is the request body for refreshing tokens.
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// RefreshToken handles POST /api/v1/auth/refresh
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	ipAddress := c.ClientIP()
	userAgent := c.Request.UserAgent()

	result, err := h.authService.RefreshAccessToken(c.Request.Context(), req.RefreshToken, &ipAddress, &userAgent)
	if err != nil {
		h.logger.Error("token refresh failed", "error", err)
		if strings.Contains(err.Error(), "invalid") || strings.Contains(err.Error(), "expired") || strings.Contains(err.Error(), "revoked") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to refresh token"})
		return
	}

	c.JSON(http.StatusOK, VerifyCodeResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    int(domain.AccessTokenTTL.Seconds()),
	})
}

// LogoutRequest is the request body for logout.
type LogoutRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// Logout handles POST /api/v1/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	var req LogoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	err := h.authService.Logout(c.Request.Context(), req.RefreshToken)
	if err != nil {
		h.logger.Error("logout failed", "error", err)
		// Still return success even if logout fails
		c.JSON(http.StatusOK, gin.H{"message": "Logged out"})
		return
	}

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

	result, err := h.authService.VerifyCode(c.Request.Context(), req.Email, req.Code, domain.ActorTypeAdmin, &ipAddress, &userAgent)
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

	c.JSON(http.StatusOK, VerifyCodeResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    int(domain.AccessTokenTTL.Seconds()),
	})
}

// JWKS handles GET /.well-known/jwks.json
func (h *AuthHandler) JWKS(c *gin.Context) {
	jwks := h.authService.GetJWKS()
	c.JSON(http.StatusOK, jwks)
}
