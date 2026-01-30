package handler

import (
	"errors"
	"net/http"

	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/ebook/internal/service"
	"github.com/gin-gonic/gin"
)

// MediaHandler handles media-related HTTP requests.
type MediaHandler struct {
	mediaService *service.MediaService
}

// NewMediaHandler creates a new MediaHandler.
func NewMediaHandler(mediaService *service.MediaService) *MediaHandler {
	return &MediaHandler{
		mediaService: mediaService,
	}
}

// UploadMedia handles POST /api/ebook/:ebook_id/media
func (h *MediaHandler) UploadMedia(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	userID := c.GetString("user_id")

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file is required"})
		return
	}
	defer file.Close()

	req := &domain.UploadMediaRequest{
		EbookID: ebookID,
		UserID:  userID,
	}

	resp, err := h.mediaService.UploadMedia(c.Request.Context(), req, file, header)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidMediaType) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "unsupported file type"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, resp)
}

// DeleteMedia handles DELETE /api/ebook/:ebook_id/media
func (h *MediaHandler) DeleteMedia(c *gin.Context) {
	ebookID := c.Param("ebook_id")
	userID := c.GetString("user_id")

	var body struct {
		S3Key    string `json:"s3_key"`
		MediaKey string `json:"media_key"`
		MediaURL string `json:"media_url"` // Legacy field
		ImageURL string `json:"image_url"` // Legacy field
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}

	// Support multiple field names for backwards compatibility
	s3Key := body.S3Key
	if s3Key == "" {
		s3Key = body.MediaKey
	}
	if s3Key == "" {
		s3Key = body.MediaURL
	}
	if s3Key == "" {
		s3Key = body.ImageURL
	}

	if s3Key == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "s3_key, media_key, media_url, or image_url is required"})
		return
	}

	req := &domain.DeleteMediaRequest{
		EbookID: ebookID,
		UserID:  userID,
		S3Key:   s3Key,
	}

	err := h.mediaService.DeleteMedia(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}

// ListPendingDeletions handles GET /api/ebook/:ebook_id/media/pending
func (h *MediaHandler) ListPendingDeletions(c *gin.Context) {
	ebookID := c.Param("ebook_id")

	pending, err := h.mediaService.ListPendingDeletions(c.Request.Context(), ebookID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"pending": pending})
}

// RegisterRoutes registers media routes on the router.
func (h *MediaHandler) RegisterRoutes(rg *gin.RouterGroup) {
	ebooks := rg.Group("/ebooks")
	{
		ebooks.POST("/:id/media", h.UploadMedia)
		ebooks.DELETE("/:id/media", h.DeleteMedia)
		ebooks.GET("/:id/media/pending", h.ListPendingDeletions)
	}
}
