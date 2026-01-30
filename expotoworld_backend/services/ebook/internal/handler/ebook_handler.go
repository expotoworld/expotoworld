// Package handler provides HTTP handlers for the ebook service.
package handler

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/service"
	"github.com/gin-gonic/gin"
)

// EbookHandler handles ebook-related HTTP requests.
type EbookHandler struct {
	ebookService *service.EbookService
}

// NewEbookHandler creates a new EbookHandler.
func NewEbookHandler(ebookService *service.EbookService) *EbookHandler {
	return &EbookHandler{
		ebookService: ebookService,
	}
}

// GetDraft handles GET /api/ebook/draft/:ebook_id
func (h *EbookHandler) GetDraft(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	userID := c.GetString("user_id")

	resp, err := h.ebookService.GetDraft(c.Request.Context(), ebookID, userID)
	if err != nil {
		if err == domain.ErrEbookNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "ebook not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// SaveDraft handles POST /api/ebook/draft/:ebook_id
func (h *EbookHandler) SaveDraft(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	userID := c.GetString("user_id")

	var body struct {
		Content json.RawMessage `json:"content"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body", "details": err.Error()})
		return
	}

	req := &domain.SaveDraftRequest{
		EbookID: ebookID,
		UserID:  userID,
		Content: body.Content,
	}

	resp, err := h.ebookService.SaveDraft(c.Request.Context(), req)
	if err != nil {
		// Log the full error for debugging
		fmt.Printf("SaveDraft error: ebookID=%s, userID=%s, error=%v\n", ebookID, userID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// RegisterRoutes registers ebook routes on the router.
func (h *EbookHandler) RegisterRoutes(rg *gin.RouterGroup) {
	ebooks := rg.Group("/ebooks")
	{
		ebooks.GET("/:id/draft", h.GetDraft)
		ebooks.POST("/:id/draft", h.SaveDraft)
	}
}
