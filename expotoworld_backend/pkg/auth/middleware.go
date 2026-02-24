package auth

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// DebugLogger is an interface for debug logging in the auth middleware.
// Any logger that implements Error and Debug methods can be used.
type DebugLogger interface {
	Error(msg string, args ...any)
	Debug(msg string, args ...any)
}

// Common role constants
const (
	RoleAdmin     = "admin"
	RoleUser      = "user"
	RoleCreator   = "creator"
	RoleModerator = "moderator"
	RoleAuthor    = "Author" // For ebook authors - case-sensitive match
)

// GinMiddlewareConfig configures the Gin auth middleware.
type GinMiddlewareConfig struct {
	Validator        *Validator
	SkipPaths        []string
	SkipPathPrefixes []string
	ErrorHandler     func(c *gin.Context, err error)
	Debug            bool // Enable debug logging for auth failures
	Logger           DebugLogger
}

// AuthErrorHandler is the default error handler for auth failures.
func AuthErrorHandler(c *gin.Context, err error) {
	status := http.StatusUnauthorized
	code := "UNAUTHORIZED"
	message := "Authentication required"

	switch err {
	case ErrMissingAuthHeader:
		message = "Missing authorization header"
	case ErrInvalidAuthHeader:
		message = "Invalid authorization header format"
	case ErrTokenExpired:
		message = "Token has expired"
	case ErrInvalidToken:
		message = "Invalid token"
	case ErrInvalidClaims:
		message = "Invalid token claims"
	case ErrKeyNotFound:
		message = "Unable to verify token"
	}

	c.AbortWithStatusJSON(status, gin.H{
		"success": false,
		"error": gin.H{
			"code":    code,
			"message": message,
		},
		"timestamp": timeNow(),
	})
}

// ForbiddenHandler handles forbidden access errors.
func ForbiddenHandler(c *gin.Context, message string) {
	if message == "" {
		message = "Access denied"
	}
	c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
		"success": false,
		"error": gin.H{
			"code":    "FORBIDDEN",
			"message": message,
		},
		"timestamp": timeNow(),
	})
}

// GinAuthMiddleware returns a Gin middleware for JWT authentication.
func GinAuthMiddleware(cfg *GinMiddlewareConfig) gin.HandlerFunc {
	errorHandler := cfg.ErrorHandler
	if errorHandler == nil {
		errorHandler = AuthErrorHandler
	}

	// Create debug error handler wrapper if debug is enabled
	debugErrorHandler := func(c *gin.Context, err error) {
		if cfg.Debug && cfg.Logger != nil {
			authHeader := c.GetHeader("Authorization")
			hasHeader := authHeader != ""
			headerLen := len(authHeader)
			headerPrefix := ""
			if headerLen > 20 {
				headerPrefix = authHeader[:20] + "..."
			} else if hasHeader {
				headerPrefix = authHeader
			}

			cfg.Logger.Error("auth middleware: token validation failed",
				"error", err.Error(),
				"path", c.Request.URL.Path,
				"method", c.Request.Method,
				"has_auth_header", hasHeader,
				"auth_header_length", headerLen,
				"auth_header_prefix", headerPrefix,
			)
		}
		errorHandler(c, err)
	}

	return func(c *gin.Context) {
		path := c.Request.URL.Path

		// Check skip paths
		for _, skipPath := range cfg.SkipPaths {
			if path == skipPath {
				c.Next()
				return
			}
		}

		// Check skip path prefixes
		for _, prefix := range cfg.SkipPathPrefixes {
			if strings.HasPrefix(path, prefix) {
				c.Next()
				return
			}
		}

		// Extract and validate token
		authHeader := c.GetHeader("Authorization")
		tokenString, err := ExtractTokenFromHeader(authHeader)
		if err != nil {
			debugErrorHandler(c, err)
			return
		}

		claims, err := cfg.Validator.ValidateToken(tokenString)
		if err != nil {
			debugErrorHandler(c, err)
			return
		}

		// Debug log successful validation
		if cfg.Debug && cfg.Logger != nil {
			cfg.Logger.Debug("auth middleware: token validated successfully",
				"path", path,
				"user_id", claims.UserID,
				"email", claims.Email,
				"issuer", claims.Issuer,
			)
		}

		// Store claims in context
		ctx := ContextWithClaims(c.Request.Context(), claims)
		c.Request = c.Request.WithContext(ctx)

		// Also store in Gin context for convenience
		c.Set("claims", claims)
		c.Set("user_id", claims.UserID)
		c.Set("email", claims.Email)
		c.Set("role", claims.Role)
		c.Set("roles", claims.Roles)
		c.Set("token", tokenString)

		c.Next()
	}
}

// RequireRoles returns a middleware that checks for required roles (any match).
func RequireRoles(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			ForbiddenHandler(c, "Authentication required")
			return
		}

		userClaims, ok := claims.(*Claims)
		if !ok {
			ForbiddenHandler(c, "Invalid authentication state")
			return
		}

		if !hasAnyRole(userClaims, roles...) {
			ForbiddenHandler(c, "Insufficient permissions")
			return
		}

		c.Next()
	}
}

// RequireAllRoles returns a middleware that checks for all required roles.
func RequireAllRoles(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			ForbiddenHandler(c, "Authentication required")
			return
		}

		userClaims, ok := claims.(*Claims)
		if !ok {
			ForbiddenHandler(c, "Invalid authentication state")
			return
		}

		if !hasAllRoles(userClaims, roles...) {
			ForbiddenHandler(c, "Insufficient permissions")
			return
		}

		c.Next()
	}
}

// RequireAdmin returns a middleware that requires admin role.
func RequireAdmin() gin.HandlerFunc {
	return RequireRoles(RoleAdmin)
}

// RequireCreator returns a middleware that requires creator or admin role.
func RequireCreator() gin.HandlerFunc {
	return RequireRoles(RoleCreator, RoleAdmin)
}

// RequireModerator returns a middleware that requires moderator or admin role.
func RequireModerator() gin.HandlerFunc {
	return RequireRoles(RoleModerator, RoleAdmin)
}

// RequireAuthor returns a middleware that requires author role (case-insensitive).
// Used by ebook service for author-only operations like editing drafts.
func RequireAuthor() gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			ForbiddenHandler(c, "Authentication required")
			return
		}

		userClaims, ok := claims.(*Claims)
		if !ok {
			ForbiddenHandler(c, "Invalid authentication state")
			return
		}

		// Case-insensitive check for "Author" role
		if !hasAuthorRole(userClaims) {
			ForbiddenHandler(c, "Author role required")
			return
		}

		c.Next()
	}
}

// RequireAdminOrAuthor returns a middleware that requires either admin or author role.
// Used by ebook service for admin-like operations that authors should also access.
func RequireAdminOrAuthor() gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			ForbiddenHandler(c, "Authentication required")
			return
		}

		userClaims, ok := claims.(*Claims)
		if !ok {
			ForbiddenHandler(c, "Invalid authentication state")
			return
		}

		// Check for admin role OR author role
		isAdmin := strings.EqualFold(userClaims.Role, RoleAdmin)
		for _, r := range userClaims.Roles {
			if strings.EqualFold(r, RoleAdmin) {
				isAdmin = true
				break
			}
		}

		if !isAdmin && !hasAuthorRole(userClaims) {
			ForbiddenHandler(c, "Admin or Author role required")
			return
		}

		c.Next()
	}
}

// OptionalAuth extracts user info if present but doesn't require it.
func OptionalAuth(validator *Validator) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.Next()
			return
		}

		tokenString, err := ExtractTokenFromHeader(authHeader)
		if err != nil {
			c.Next()
			return
		}

		claims, err := validator.ValidateToken(tokenString)
		if err != nil {
			c.Next()
			return
		}

		ctx := ContextWithClaims(c.Request.Context(), claims)
		c.Request = c.Request.WithContext(ctx)
		c.Set("claims", claims)
		c.Set("user_id", claims.UserID)
		c.Set("email", claims.Email)
		c.Set("role", claims.Role)
		c.Set("roles", claims.Roles)
		c.Set("token", tokenString)

		c.Next()
	}
}

// GetClaimsFromContext retrieves claims from Gin context.
func GetClaimsFromContext(c *gin.Context) (*Claims, bool) {
	claims, exists := c.Get("claims")
	if !exists {
		return nil, false
	}
	userClaims, ok := claims.(*Claims)
	return userClaims, ok
}

// GetClaims retrieves claims from Gin context (alias for GetClaimsFromContext).
func GetClaims(c *gin.Context) *Claims {
	claims, _ := GetClaimsFromContext(c)
	return claims
}

// GetUserIDFromGinContext retrieves user ID from Gin context.
func GetUserIDFromGinContext(c *gin.Context) string {
	if userID, exists := c.Get("user_id"); exists {
		if id, ok := userID.(string); ok {
			return id
		}
	}
	return ""
}

// IsAdmin checks if the current user has admin role.
func IsAdmin(c *gin.Context) bool {
	claims, ok := GetClaimsFromContext(c)
	if !ok {
		return false
	}
	return hasAnyRole(claims, RoleAdmin)
}

// IsModerator checks if the current user has moderator or admin role.
func IsModerator(c *gin.Context) bool {
	claims, ok := GetClaimsFromContext(c)
	if !ok {
		return false
	}
	return hasAnyRole(claims, RoleModerator, RoleAdmin)
}

// IsCreator checks if the current user has creator or admin role.
func IsCreator(c *gin.Context) bool {
	claims, ok := GetClaimsFromContext(c)
	if !ok {
		return false
	}
	return hasAnyRole(claims, RoleCreator, RoleAdmin)
}

// IsAuthor checks if the current user has author role (case-insensitive).
func IsAuthor(c *gin.Context) bool {
	claims, ok := GetClaimsFromContext(c)
	if !ok {
		return false
	}
	return hasAuthorRole(claims)
}

// hasAnyRole checks if claims have any of the specified roles (case-insensitive).
func hasAnyRole(claims *Claims, roles ...string) bool {
	for _, role := range roles {
		if strings.EqualFold(claims.Role, role) {
			return true
		}
		for _, r := range claims.Roles {
			if strings.EqualFold(r, role) {
				return true
			}
		}
	}
	return false
}

// hasAllRoles checks if claims have all of the specified roles (case-insensitive).
func hasAllRoles(claims *Claims, roles ...string) bool {
	roleSet := make(map[string]bool)
	roleSet[strings.ToLower(claims.Role)] = true
	for _, r := range claims.Roles {
		roleSet[strings.ToLower(r)] = true
	}

	for _, role := range roles {
		if !roleSet[strings.ToLower(role)] {
			return false
		}
	}
	return true
}

// timeNow returns current time in RFC3339 format.
func timeNow() string {
	return time.Now().UTC().Format(time.RFC3339)
}

// hasAuthorRole checks if claims have author role (case-insensitive).
func hasAuthorRole(claims *Claims) bool {
	if strings.EqualFold(claims.Role, RoleAuthor) {
		return true
	}
	for _, r := range claims.Roles {
		if strings.EqualFold(r, RoleAuthor) {
			return true
		}
	}
	return false
}
