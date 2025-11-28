package api

import (
	"net/http"
	"strings"

	"github.com/expotoworld/expotoworld/backend/order-service/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware validates JWT tokens
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "Authorization header required",
				Message: "Please provide a valid authorization token",
			})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>"
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "Invalid authorization format",
				Message: "Authorization header must be in format 'Bearer <token>'",
			})
			c.Abort()
			return
		}

		tokenString := tokenParts[1]

		// Parse and validate token using JWKS (RS256)
		token, err := jwt.Parse(tokenString, keyFuncFromJWKS)

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "Invalid token",
				Message: "The provided token is invalid or expired",
			})
			c.Abort()
			return
		}

		// Extract claims
		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			c.Set("user_id", claims["user_id"])
			c.Set("email", claims["email"])
			if r, ok := claims["role"].(string); ok {
				c.Set("role", r)
			}
			if orgs, ok := claims["org_memberships"]; ok {
				c.Set("org_memberships", orgs)
			}
		}

		c.Next()
	}
}

// GetUserID extracts user ID from the JWT token claims
func GetUserID(c *gin.Context) (string, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		return "", false
	}

	userIDStr, ok := userID.(string)
	return userIDStr, ok
}

// ValidateMiniAppType validates and returns the mini-app type from URL parameter.
// Only ETW identifiers are accepted (ETWtoB, ETWtoC, ETWtoU, ETWtoG).
func ValidateMiniAppType(c *gin.Context) (models.MiniAppType, bool) {
	miniAppTypeStr := c.Param("mini_app_type")
	miniAppType, ok := models.ParseMiniAppTypeFromString(miniAppTypeStr)
	if !ok {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid mini-app type",
			Message: "Mini-app type must be one of: ETWtoB, ETWtoC, ETWtoU, ETWtoG",
		})
		return "", false
	}
	return miniAppType, true
}

// AdminMiddleware ensures the user has strict Admin role for admin endpoints
func AdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		roleVal, exists := c.Get("role")
		role, _ := roleVal.(string)
		if !exists || role != "Admin" {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Error:   "Admin access required",
				Message: "Admin role required",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}
