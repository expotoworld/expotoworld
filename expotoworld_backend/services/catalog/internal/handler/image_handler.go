// Package handler provides HTTP handlers for the catalog service.
package handler

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/expotoworld/expotoworld_backend/pkg/awsutil"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
)

// ImageHandler handles HTTP requests for product images.
type ImageHandler struct {
	imageRepo  repository.ImageRepository
	s3Client   *awsutil.S3Client
	s3BasePath string // e.g., "admin-panel/products"
}

// Helper functions for pointer dereferencing
func derefInt32(p *int32) int32 {
	if p == nil {
		return 0
	}
	return *p
}

func derefString(p *string) string {
	if p == nil {
		return ""
	}
	return *p
}

// NewImageHandler creates a new image handler.
func NewImageHandler(imageRepo repository.ImageRepository, s3Client *awsutil.S3Client, s3BasePath string) *ImageHandler {
	return &ImageHandler{
		imageRepo:  imageRepo,
		s3Client:   s3Client,
		s3BasePath: s3BasePath,
	}
}

// RegisterRoutes registers image routes.
func (h *ImageHandler) RegisterRoutes(r *gin.RouterGroup) {
	images := r.Group("/products/:id/images")
	{
		images.GET("/upload-url", h.GetUploadURL)
		images.POST("", h.CreateImage)
		images.DELETE("/:imageId", h.DeleteImage)
		images.PUT("/:imageId/primary", h.SetPrimaryImage)
		images.PUT("/reorder", h.ReorderImages)
	}

	// S3 orphan cleanup endpoint
	r.DELETE("/s3-cleanup", h.CleanupS3Object)
}

// GetUploadURLRequest represents a request to get a presigned upload URL.
type GetUploadURLRequest struct {
	FileName    string `form:"file_name" binding:"required"`
	ContentType string `form:"content_type" binding:"required"`
}

// GetUploadURLResponse represents a response containing the presigned upload URL.
type GetUploadURLResponse struct {
	UploadURL string `json:"upload_url"`
	ObjectKey string `json:"object_key"`
	PublicURL string `json:"public_url"`
	ExpiresIn int    `json:"expires_in"` // seconds
}

// GetUploadURL handles GET /products/:id/images/upload-url
// Returns a presigned URL for direct upload to S3.
func (h *ImageHandler) GetUploadURL(c *gin.Context) {
	productID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	var req GetUploadURLRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	// Validate content type
	if !isValidImageContentType(req.ContentType) {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid content type, must be image/jpeg, image/png, image/gif, or image/webp"})
		return
	}

	// Generate unique S3 key
	ext := filepath.Ext(req.FileName)
	if ext == "" {
		ext = getExtensionFromContentType(req.ContentType)
	}
	uniqueID := uuid.New().String()
	objectKey := fmt.Sprintf("%s/%d/images/%s%s", h.s3BasePath, productID, uniqueID, ext)

	// Generate presigned URL (valid for 15 minutes)
	expiresIn := 15 * time.Minute
	uploadURL, err := h.s3Client.GeneratePresignedUploadURL(c.Request.Context(), objectKey, req.ContentType, expiresIn)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to generate upload URL"})
		return
	}

	c.JSON(http.StatusOK, GetUploadURLResponse{
		UploadURL: uploadURL,
		ObjectKey: objectKey,
		PublicURL: h.s3Client.GetPublicURL(objectKey),
		ExpiresIn: int(expiresIn.Seconds()),
	})
}

// CreateImageRequest represents a request to create an image record.
type CreateImageRequest struct {
	ImageURL     string `json:"image_url" binding:"required"`
	DisplayOrder int32  `json:"display_order"`
	IsPrimary    bool   `json:"is_primary"`
}

// CreateImageResponse represents a created image.
type CreateImageResponse struct {
	ImageID      int32  `json:"image_id"`
	ProductID    int32  `json:"product_id"`
	ImageURL     string `json:"image_url"`
	DisplayOrder int32  `json:"display_order"`
	IsPrimary    bool   `json:"is_primary"`
	CreatedAt    string `json:"created_at"`
}

// CreateImage handles POST /products/:id/images
// Creates an image record after the file has been uploaded to S3.
func (h *ImageHandler) CreateImage(c *gin.Context) {
	productID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	var req CreateImageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	// Create image record
	params := &domain.CreateImageParams{
		ProductID:    productID,
		ImageURL:     req.ImageURL,
		DisplayOrder: req.DisplayOrder,
		IsPrimary:    req.IsPrimary,
	}

	image, err := h.imageRepo.Create(c.Request.Context(), params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to create image"})
		return
	}

	c.JSON(http.StatusCreated, CreateImageResponse{
		ImageID:      image.ImageID,
		ProductID:    derefInt32(image.ProductID),
		ImageURL:     derefString(image.ImageURL),
		DisplayOrder: image.DisplayOrder,
		IsPrimary:    image.IsPrimary,
		CreatedAt:    image.CreatedAt.Format(time.RFC3339),
	})
}

// DeleteImage handles DELETE /products/:id/images/:imageId
// Deletes both the database record and the S3 object.
func (h *ImageHandler) DeleteImage(c *gin.Context) {
	productID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	imageID, err := parseID(c, "imageId")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid image id"})
		return
	}

	// Get the image to retrieve the S3 key
	image, err := h.imageRepo.GetByID(c.Request.Context(), imageID)
	if err != nil {
		if err == domain.ErrImageNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "image not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to get image"})
		return
	}

	// Verify the image belongs to the product
	if image.ProductID == nil || *image.ProductID != productID {
		c.JSON(http.StatusForbidden, ErrorResponse{Error: "image does not belong to this product"})
		return
	}

	// Extract S3 key from the URL if it's an S3 URL
	s3Key := extractS3Key(derefString(image.ImageURL), h.s3Client.GetBucket())

	// Delete from database first
	if err := h.imageRepo.Delete(c.Request.Context(), imageID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to delete image"})
		return
	}

	// Delete from S3 if it's an S3 URL (best effort, don't fail if S3 delete fails)
	if s3Key != "" {
		if err := h.s3Client.DeleteObject(c.Request.Context(), s3Key); err != nil {
			// Log but don't fail - image record is already deleted
			fmt.Printf("warning: failed to delete S3 object %s: %v\n", s3Key, err)
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "image deleted successfully"})
}

// SetPrimaryImage handles PUT /products/:id/images/:imageId/primary
func (h *ImageHandler) SetPrimaryImage(c *gin.Context) {
	productID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	imageID, err := parseID(c, "imageId")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid image id"})
		return
	}

	if err := h.imageRepo.SetPrimary(c.Request.Context(), productID, imageID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to set primary image"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "primary image updated successfully"})
}

// ReorderImagesRequest represents a request to reorder images.
type ReorderImagesRequest struct {
	ImageIDs []int32 `json:"image_ids" binding:"required,min=1"`
}

// ReorderImages handles PUT /products/:id/images/reorder
func (h *ImageHandler) ReorderImages(c *gin.Context) {
	productID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	var req ReorderImagesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	if err := h.imageRepo.Reorder(c.Request.Context(), productID, req.ImageIDs); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to reorder images"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "images reordered successfully"})
}

// CleanupS3Object handles DELETE /s3-cleanup?object_key=...
// Removes an orphaned S3 object that was uploaded but whose DB record creation failed.
// Only allows deletion of objects under the admin-panel/ prefix for safety.
func (h *ImageHandler) CleanupS3Object(c *gin.Context) {
	objectKey := c.Query("object_key")
	if objectKey == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "object_key query parameter is required"})
		return
	}

	// Security: only allow cleanup of objects under admin-panel/ prefix
	allowedPrefixes := []string{
		"admin-panel/products/",
		"admin-panel/categories/",
		"admin-panel/subcategories/",
		"admin-panel/stores/",
	}
	allowed := false
	for _, prefix := range allowedPrefixes {
		if strings.HasPrefix(objectKey, prefix) {
			allowed = true
			break
		}
	}
	if !allowed {
		c.JSON(http.StatusForbidden, ErrorResponse{Error: "object key not in an allowed path"})
		return
	}

	if err := h.s3Client.DeleteObject(c.Request.Context(), objectKey); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to delete S3 object"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "S3 object deleted successfully", "object_key": objectKey})
}

// ---- Helper functions ----

func isValidImageContentType(contentType string) bool {
	validTypes := map[string]bool{
		"image/jpeg": true,
		"image/jpg":  true,
		"image/png":  true,
		"image/gif":  true,
		"image/webp": true,
	}
	return validTypes[contentType]
}

func getExtensionFromContentType(contentType string) string {
	extensions := map[string]string{
		"image/jpeg": ".jpg",
		"image/jpg":  ".jpg",
		"image/png":  ".png",
		"image/gif":  ".gif",
		"image/webp": ".webp",
	}
	if ext, ok := extensions[contentType]; ok {
		return ext
	}
	return ".jpg" // default
}

// extractS3Key extracts the S3 object key from a URL.
// Returns empty string if not an S3 URL for the specified bucket.
func extractS3Key(imageURL, bucket string) string {
	// Handle S3 URL format: https://bucket.s3.amazonaws.com/key
	s3Prefix := fmt.Sprintf("https://%s.s3.amazonaws.com/", bucket)
	if strings.HasPrefix(imageURL, s3Prefix) {
		return strings.TrimPrefix(imageURL, s3Prefix)
	}

	// Handle S3 URL format: https://s3.region.amazonaws.com/bucket/key
	if strings.Contains(imageURL, ".amazonaws.com/"+bucket+"/") {
		parts := strings.SplitN(imageURL, "/"+bucket+"/", 2)
		if len(parts) == 2 {
			return parts[1]
		}
	}

	// Handle CloudFront or custom domain URLs
	// If the URL contains our expected path structure, extract it
	if strings.Contains(imageURL, "admin-panel/") {
		idx := strings.Index(imageURL, "admin-panel/")
		if idx != -1 {
			return imageURL[idx:]
		}
	}

	return ""
}
