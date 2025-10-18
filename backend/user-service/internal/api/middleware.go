package api

import (
	"net/http"
	"os"
	"strings"

	"github.com/expotoworld/expotoworld/backend/user-service/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware validates JWT tokens for admin access
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// For development/testing, allow requests with dummy token
		authHeader := c.GetHeader("Authorization")
		if authHeader == "Bearer dummy-token-for-development" {
			c.Set("user_id", "test-admin-user")
			c.Set("email", "admin@test.com")
			c.Set("role", "Admin")
			c.Next()
			return
		}

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

		// Parse and validate token
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Error:   "Server not configured",
				Message: "JWT secret missing",
			})
			c.Abort()
			return
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(secret), nil
		})

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
		}

		c.Next()
	}
}

// AdminMiddleware ensures the user has admin-panel privileges based on JWT role claim
func AdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		roleVal, exists := c.Get("role")
		role, _ := roleVal.(string)
		allowed := map[string]bool{"Admin": true, "Manufacturer": true, "3PL": true, "Partner": true}
		if !exists || !allowed[role] {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Error:   "Admin access required",
				Message: "Valid admin/manufacturer/3PL/partner role required",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// CORSMiddleware handles CORS headers
func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
