package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/service"
	"github.com/gin-gonic/gin"
)

// VersionHandler handles version-related HTTP requests.
type VersionHandler struct {
	versionService *service.VersionService
}

// NewVersionHandler creates a new VersionHandler.
func NewVersionHandler(versionService *service.VersionService) *VersionHandler {
	return &VersionHandler{
		versionService: versionService,
	}
}

// ListVersions handles GET /api/ebook/:ebook_id/versions
func (h *VersionHandler) ListVersions(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	kind := c.Query("kind") // Optional filter by kind (manual/published)

	req := &domain.ListVersionsRequest{
		EbookID: ebookID,
		Kind:    kind,
	}

	resp, err := h.versionService.ListVersions(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return in format expected by frontend: { items: [...], kind, limit, offset }
	c.JSON(http.StatusOK, gin.H{
		"items":              resp.Versions,
		"kind":               kind,
		"current_version_id": resp.CurrentVersionID,
	})
}

// CreateVersion handles POST /api/ebook/:ebook_id/versions
func (h *VersionHandler) CreateVersion(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	userID := c.GetString("user_id")

	var body struct {
		Label string `json:"label"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	req := &domain.CreateVersionRequest{
		EbookID: ebookID,
		Label:   body.Label,
		UserID:  userID,
	}

	resp, err := h.versionService.CreateVersion(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, resp)
}

// PublishVersion handles POST /api/ebook/:ebook_id/versions/:version_id/publish
func (h *VersionHandler) PublishVersion(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	versionID := c.Param("version_id")
	userID := c.GetString("user_id")

	// Parse optional label from request body
	var body struct {
		Label string `json:"label"`
	}
	_ = c.ShouldBindJSON(&body) // Ignore error - body is optional

	req := &domain.PublishVersionRequest{
		EbookID:   ebookID,
		VersionID: versionID,
		UserID:    userID,
		Label:     body.Label,
	}

	resp, err := h.versionService.PublishVersion(c.Request.Context(), req)
	if err != nil {
		if errors.Is(err, domain.ErrVersionNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// RestoreVersion handles POST /api/ebook/:ebook_id/versions/:version_id/restore
func (h *VersionHandler) RestoreVersion(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	versionID := c.Param("version_id")
	userID := c.GetString("user_id")

	req := &domain.RestoreVersionRequest{
		EbookID:   ebookID,
		VersionID: versionID,
		UserID:    userID,
	}

	resp, err := h.versionService.RestoreVersion(c.Request.Context(), req)
	if err != nil {
		if errors.Is(err, domain.ErrVersionNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// DeleteVersion handles DELETE /api/ebook/:ebook_id/versions/:version_id
func (h *VersionHandler) DeleteVersion(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	versionID := c.Param("version_id")

	req := &domain.DeleteVersionRequest{
		EbookID:   ebookID,
		VersionID: versionID,
	}

	err := h.versionService.DeleteVersion(c.Request.Context(), req)
	if err != nil {
		if errors.Is(err, domain.ErrVersionNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}
		if errors.Is(err, domain.ErrCannotDeletePublished) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "cannot delete currently published version"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}

// GetVersionContent handles GET /api/ebook/:ebook_id/versions/:version_id/content
func (h *VersionHandler) GetVersionContent(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	versionID := c.Param("version_id")

	content, err := h.versionService.GetVersionContent(c.Request.Context(), ebookID, versionID)
	if err != nil {
		if errors.Is(err, domain.ErrVersionNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Wrap content in { "content": ... } to match frontend expectation
	c.JSON(http.StatusOK, gin.H{"content": json.RawMessage(content)})
}

// UpdateVersionLabel handles PATCH /api/ebook/:ebook_id/versions/:version_id
func (h *VersionHandler) UpdateVersionLabel(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	versionID := c.Param("version_id")

	var body struct {
		Label string `json:"label"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	if body.Label == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "label is required"})
		return
	}

	err := h.versionService.UpdateVersionLabel(c.Request.Context(), ebookID, versionID, body.Label)
	if err != nil {
		if errors.Is(err, domain.ErrVersionNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "version not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}

// RegisterRoutes registers version routes on the router.
func (h *VersionHandler) RegisterRoutes(rg *gin.RouterGroup) {
	ebooks := rg.Group("/ebooks")
	{
		ebooks.GET("/:id/versions", h.ListVersions)
		ebooks.POST("/:id/versions", h.CreateVersion)
		ebooks.POST("/:id/versions/:versionId/publish", h.PublishVersion)
		ebooks.POST("/:id/versions/:versionId/restore", h.RestoreVersion)
		ebooks.DELETE("/:id/versions/:versionId", h.DeleteVersion)
		ebooks.GET("/:id/versions/:versionId/content", h.GetVersionContent)
	}
}
