package api

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

// setGinTestMode ensures Gin does not write noisy logs during tests
func setGinTestMode() { gin.SetMode(gin.TestMode) }

func TestLiveEndpoint(t *testing.T) {
	setGinTestMode()
	r := gin.New()
	r.GET("/live", func(c *gin.Context) { c.Status(http.StatusOK) })

	req := httptest.NewRequest(http.MethodGet, "/live", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", w.Code)
	}
}

func TestAuthMiddleware_AllowsDummyToken(t *testing.T) {
	setGinTestMode()
	r := gin.New()
	r.Use(AuthMiddleware(), AdminMiddleware())
	r.GET("/api/admin/ping", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"ok": true}) })

	req := httptest.NewRequest(http.MethodGet, "/api/admin/ping", nil)
	req.Header.Set("Authorization", "Bearer dummy-token-for-development")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for dummy token, got %d", w.Code)
	}
}

func TestAuthMiddleware_RejectsMissingToken(t *testing.T) {
	setGinTestMode()
	r := gin.New()
	r.Use(AuthMiddleware(), AdminMiddleware())
	r.GET("/api/admin/ping", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"ok": true}) })

	req := httptest.NewRequest(http.MethodGet, "/api/admin/ping", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for missing token, got %d", w.Code)
	}
}
