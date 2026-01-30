package handler

import (
	"net/http"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/service"
	"github.com/gin-gonic/gin"
)

// AdminHandler handles admin-related HTTP requests.
type AdminHandler struct {
	mediaService *service.MediaService
}

// NewAdminHandler creates a new AdminHandler.
func NewAdminHandler(mediaService *service.MediaService) *AdminHandler {
	return &AdminHandler{
		mediaService: mediaService,
	}
}

// ListPendingDeletions handles GET /admin/pending
func (h *AdminHandler) ListPendingDeletions(c *gin.Context) {
	// For the single ebook system, use "huashangdao" as default
	ebookID := c.DefaultQuery("ebook_id", "huashangdao")
	limit := c.DefaultQuery("limit", "20")
	offset := c.DefaultQuery("offset", "0")

	pending, err := h.mediaService.ListPendingDeletions(c.Request.Context(), ebookID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return in format expected by frontend: { items: [...] }
	c.JSON(http.StatusOK, gin.H{
		"items":  pending,
		"limit":  limit,
		"offset": offset,
	})
}

// RegisterAdminRoutes registers admin routes on the router.
func (h *AdminHandler) RegisterAdminRoutes(rg *gin.RouterGroup) {
	admin := rg.Group("/admin")
	{
		admin.GET("/pending", h.ListPendingDeletions)
	}
}
