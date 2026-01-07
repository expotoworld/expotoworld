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
type SendCodeRequest struct {
	Email string `json:"email" binding:"required,email"`
}

// SendCodeResponse is the response for sending a verification code.
type SendCodeResponse struct {
	Message string `json:"message"`
}

// SendCode handles POST /api/v1/auth/send-code
func (h *AuthHandler) SendCode(c *gin.Context) {
	var req SendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid email address"})
		return
	}

	ipAddress := c.ClientIP()
	err := h.authService.SendVerificationCode(c.Request.Context(), req.Email, domain.ActorTypeUser, ipAddress)
	if err != nil {
		h.logger.Error("failed to send verification code", "error", err, "email", req.Email)
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
type VerifyCodeRequest struct {
	Email string `json:"email" binding:"required,email"`
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

	ipAddress := c.ClientIP()
	userAgent := c.Request.UserAgent()

	result, err := h.authService.VerifyCode(c.Request.Context(), req.Email, req.Code, domain.ActorTypeUser, &ipAddress, &userAgent)
	if err != nil {
		h.logger.Error("verification failed", "error", err, "email", req.Email)
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
