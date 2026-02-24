package handler

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/expotoworld/expotoworld_backend/pkg/awsutil"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/service"
)

// CategoryHandler handles HTTP requests for categories and subcategories.
type CategoryHandler struct {
	categoryService *service.CategoryService
	s3Client        *awsutil.S3Client
	s3BasePath      string // e.g., "admin-panel/categories"
}

// NewCategoryHandler creates a new category handler.
func NewCategoryHandler(categoryService *service.CategoryService, s3Client *awsutil.S3Client, s3BasePath string) *CategoryHandler {
	return &CategoryHandler{
		categoryService: categoryService,
		s3Client:        s3Client,
		s3BasePath:      s3BasePath,
	}
}

// RegisterRoutes registers category routes.
func (h *CategoryHandler) RegisterRoutes(r *gin.RouterGroup) {
	categories := r.Group("/categories")
	{
		categories.GET("", h.ListCategories)
		categories.POST("", h.CreateCategory)
		categories.GET("/tree", h.GetCategoryTree)
		categories.GET("/tree/full", h.GetCategoryTreeFull)
		categories.GET("/:id", h.GetCategory)
		categories.PUT("/:id", h.UpdateCategory)
		categories.DELETE("/:id", h.DeleteCategory)
		categories.PUT("/reorder", h.ReorderCategories)
		categories.GET("/:id/image/upload-url", h.GetCategoryImageUploadURL)

		// Subcategory routes under category
		categories.GET("/:id/subcategories", h.GetSubcategories)
		categories.POST("/:id/subcategories", h.CreateSubcategory)
		categories.PUT("/:id/subcategories/reorder", h.ReorderSubcategories)
	}

	// Direct subcategory routes
	subcategories := r.Group("/subcategories")
	{
		subcategories.GET("/:id", h.GetSubcategory)
		subcategories.PUT("/:id", h.UpdateSubcategory)
		subcategories.DELETE("/:id", h.DeleteSubcategory)
		subcategories.PUT("/:id/move", h.MoveSubcategory)
		subcategories.GET("/:id/image/upload-url", h.GetSubcategoryImageUploadURL)

		// Collection routes under subcategory
		subcategories.GET("/:id/collections", h.GetCollections)
		subcategories.POST("/:id/collections", h.CreateCollection)
		subcategories.PUT("/:id/collections/reorder", h.ReorderCollections)
	}

	// Direct collection routes
	collections := r.Group("/collections")
	{
		collections.GET("/:id", h.GetCollection)
		collections.PUT("/:id", h.UpdateCollection)
		collections.DELETE("/:id", h.DeleteCollection)
		collections.PUT("/:id/move", h.MoveCollection)
		collections.GET("/:id/image/upload-url", h.GetCollectionImageUploadURL)
	}
}

// ListCategories handles GET /categories
func (h *CategoryHandler) ListCategories(c *gin.Context) {
	pagination := parsePagination(c)
	filter := parseCategoryFilter(c)

	result, err := h.categoryService.ListCategories(c.Request.Context(), filter, pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toPaginatedCategoriesResponse(result))
}

// GetCategoryTree handles GET /categories/tree
func (h *CategoryHandler) GetCategoryTree(c *gin.Context) {
	filter := parseCategoryFilter(c)

	result, err := h.categoryService.GetCategoryTree(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toCategoryTreeResponse(result))
}

// CreateCategory handles POST /categories
func (h *CategoryHandler) CreateCategory(c *gin.Context) {
	var req CreateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	params := req.toParams()
	result, err := h.categoryService.CreateCategory(c.Request.Context(), params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toCategoryResponse(result))
}

// GetCategory handles GET /categories/:id
func (h *CategoryHandler) GetCategory(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	// Check if subcategories are requested
	if c.Query("with_subcategories") == "true" {
		result, err := h.categoryService.GetCategoryWithSubcategories(c.Request.Context(), id)
		if err != nil {
			if err == domain.ErrCategoryNotFound {
				c.JSON(http.StatusNotFound, ErrorResponse{Error: "category not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
			return
		}
		c.JSON(http.StatusOK, toCategoryWithSubcategoriesResponse(result))
		return
	}

	result, err := h.categoryService.GetCategory(c.Request.Context(), id)
	if err != nil {
		if err == domain.ErrCategoryNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "category not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toCategoryResponse(result))
}

// UpdateCategory handles PUT /categories/:id
func (h *CategoryHandler) UpdateCategory(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	var req UpdateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	params := req.toParams()
	result, err := h.categoryService.UpdateCategory(c.Request.Context(), id, params)
	if err != nil {
		if err == domain.ErrCategoryNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "category not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toCategoryResponse(result))
}

// DeleteCategory handles DELETE /categories/:id
func (h *CategoryHandler) DeleteCategory(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	if err := h.categoryService.DeleteCategory(c.Request.Context(), id); err != nil {
		if err == domain.ErrCategoryNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "category not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "category deleted successfully"})
}

// ReorderCategories handles PUT /categories/reorder
func (h *CategoryHandler) ReorderCategories(c *gin.Context) {
	var req ReorderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	if err := h.categoryService.ReorderCategories(c.Request.Context(), req.OrderedIDs); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "categories reordered successfully"})
}

// GetSubcategories handles GET /categories/:id/subcategories
func (h *CategoryHandler) GetSubcategories(c *gin.Context) {
	categoryID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	result, err := h.categoryService.GetSubcategoriesByCategory(c.Request.Context(), categoryID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toSubcategoriesResponse(result))
}

// CreateSubcategory handles POST /categories/:id/subcategories
func (h *CategoryHandler) CreateSubcategory(c *gin.Context) {
	categoryID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	var req CreateSubcategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	params := req.toParams(categoryID)
	result, err := h.categoryService.CreateSubcategory(c.Request.Context(), params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toSubcategoryResponse(result))
}

// ReorderSubcategories handles PUT /categories/:id/subcategories/reorder
func (h *CategoryHandler) ReorderSubcategories(c *gin.Context) {
	categoryID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	var req ReorderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	if err := h.categoryService.ReorderSubcategories(c.Request.Context(), categoryID, req.OrderedIDs); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "subcategories reordered successfully"})
}

// GetSubcategory handles GET /subcategories/:id
func (h *CategoryHandler) GetSubcategory(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	result, err := h.categoryService.GetSubcategory(c.Request.Context(), id)
	if err != nil {
		if err == domain.ErrSubcategoryNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "subcategory not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toSubcategoryResponse(result))
}

// UpdateSubcategory handles PUT /subcategories/:id
func (h *CategoryHandler) UpdateSubcategory(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	var req UpdateSubcategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	params := req.toParams()
	result, err := h.categoryService.UpdateSubcategory(c.Request.Context(), id, params)
	if err != nil {
		if err == domain.ErrSubcategoryNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "subcategory not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toSubcategoryResponse(result))
}

// DeleteSubcategory handles DELETE /subcategories/:id
func (h *CategoryHandler) DeleteSubcategory(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	if err := h.categoryService.DeleteSubcategory(c.Request.Context(), id); err != nil {
		if err == domain.ErrSubcategoryNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "subcategory not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "subcategory deleted successfully"})
}

// MoveSubcategory handles PUT /subcategories/:id/move
func (h *CategoryHandler) MoveSubcategory(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	var req MoveSubcategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	if err := h.categoryService.MoveSubcategory(c.Request.Context(), id, req.TargetCategoryID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	// Fetch the updated subcategory
	result, err := h.categoryService.GetSubcategory(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toSubcategoryResponse(result))
}

// ----------------------------------------------------------------
// Collection Handlers
// ----------------------------------------------------------------

// GetCategoryTreeFull handles GET /categories/tree/full (3-tier)
func (h *CategoryHandler) GetCategoryTreeFull(c *gin.Context) {
	filter := parseCategoryFilter(c)

	result, err := h.categoryService.GetCategoryTreeFull(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toCategoryTreeFullResponse(result))
}

// GetCollections handles GET /subcategories/:id/collections
func (h *CategoryHandler) GetCollections(c *gin.Context) {
	subcategoryID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	result, err := h.categoryService.GetCollectionsBySubcategory(c.Request.Context(), subcategoryID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toCollectionsResponse(result))
}

// CreateCollection handles POST /subcategories/:id/collections
func (h *CategoryHandler) CreateCollection(c *gin.Context) {
	subcategoryID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	var req CreateCollectionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	params := req.toParams(subcategoryID)
	result, err := h.categoryService.CreateCollection(c.Request.Context(), params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toCollectionResponse(result))
}

// ReorderCollections handles PUT /subcategories/:id/collections/reorder
func (h *CategoryHandler) ReorderCollections(c *gin.Context) {
	subcategoryID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	var req ReorderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	if err := h.categoryService.ReorderCollections(c.Request.Context(), subcategoryID, req.OrderedIDs); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "collections reordered successfully"})
}

// GetCollection handles GET /collections/:id
func (h *CategoryHandler) GetCollection(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid collection id"})
		return
	}

	result, err := h.categoryService.GetCollection(c.Request.Context(), id)
	if err != nil {
		if err == domain.ErrCollectionNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "collection not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toCollectionWithCountsResponse(result))
}

// UpdateCollection handles PUT /collections/:id
func (h *CategoryHandler) UpdateCollection(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid collection id"})
		return
	}

	var req UpdateCollectionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	params := req.toParams()
	result, err := h.categoryService.UpdateCollection(c.Request.Context(), id, params)
	if err != nil {
		if err == domain.ErrCollectionNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "collection not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toCollectionResponse(result))
}

// DeleteCollection handles DELETE /collections/:id
func (h *CategoryHandler) DeleteCollection(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid collection id"})
		return
	}

	if err := h.categoryService.DeleteCollection(c.Request.Context(), id); err != nil {
		if err == domain.ErrCollectionNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "collection not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "collection deleted successfully"})
}

// MoveCollection handles PUT /collections/:id/move
func (h *CategoryHandler) MoveCollection(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid collection id"})
		return
	}

	var req MoveCollectionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	if err := h.categoryService.MoveCollection(c.Request.Context(), id, req.TargetSubcategoryID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	// Fetch the updated collection
	result, err := h.categoryService.GetCollection(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toCollectionWithCountsResponse(result))
}

// GetCollectionImageUploadURL handles GET /collections/:id/image/upload-url
func (h *CategoryHandler) GetCollectionImageUploadURL(c *gin.Context) {
	collectionID, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid collection id"})
		return
	}

	var req ImageUploadURLRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	if !isValidImageContentType(req.ContentType) {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid content type, must be image/jpeg, image/png, image/gif, or image/webp"})
		return
	}

	ext := filepath.Ext(req.FileName)
	if ext == "" {
		ext = getExtensionFromContentType(req.ContentType)
	}
	uniqueID := uuid.New().String()
	objectKey := fmt.Sprintf("admin-panel/collections/%d/image/%s%s", collectionID, uniqueID, ext)

	expiresIn := 15 * time.Minute
	uploadURL, err := h.s3Client.GeneratePresignedUploadURL(c.Request.Context(), objectKey, req.ContentType, expiresIn)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to generate upload URL"})
		return
	}

	c.JSON(http.StatusOK, ImageUploadURLResponse{
		UploadURL: uploadURL,
		ObjectKey: objectKey,
		PublicURL: h.s3Client.GetPublicURL(objectKey),
		ExpiresIn: int(expiresIn.Seconds()),
	})
}

// Helper functions

func parseCategoryFilter(c *gin.Context) *domain.CategoryFilter {
	filter := &domain.CategoryFilter{}

	if storeID := c.Query("store_id"); storeID != "" {
		if id, err := strconv.ParseInt(storeID, 10, 32); err == nil {
			sid := int32(id)
			filter.StoreID = &sid
		}
	}

	if isActive := c.Query("is_active"); isActive != "" {
		active := isActive == "true"
		filter.IsActive = &active
	}

	if etwStoreType := c.Query("etw_store_type"); etwStoreType != "" {
		st := domain.ETWStoreType(etwStoreType)
		filter.ETWStoreType = &st
	}

	if etwMiniAppType := c.Query("etw_mini_app_type"); etwMiniAppType != "" {
		mt := domain.ETWMiniAppType(etwMiniAppType)
		filter.ETWMiniAppType = &mt
	}

	if search := c.Query("search"); search != "" {
		filter.Search = &search
	}

	return filter
}

// ImageUploadURLRequest represents a request to get a presigned upload URL for an image.
type ImageUploadURLRequest struct {
	FileName    string `form:"file_name" binding:"required"`
	ContentType string `form:"content_type" binding:"required"`
}

// ImageUploadURLResponse represents a response containing the presigned upload URL.
type ImageUploadURLResponse struct {
	UploadURL string `json:"upload_url"`
	ObjectKey string `json:"object_key"`
	PublicURL string `json:"public_url"`
	ExpiresIn int    `json:"expires_in"` // seconds
}

// GetCategoryImageUploadURL godoc
// @Summary Get presigned URL for uploading a category image
// @Tags categories
// @Accept json
// @Produce json
// @Param id path int true "Category ID"
// @Param file_name query string true "File name"
// @Param content_type query string true "Content type (e.g., image/jpeg)"
// @Success 200 {object} ImageUploadURLResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /categories/{id}/image/upload-url [get]
func (h *CategoryHandler) GetCategoryImageUploadURL(c *gin.Context) {
	categoryID, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	var req ImageUploadURLRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	// Validate content type
	if !isValidImageContentType(req.ContentType) {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid content type, must be image/jpeg, image/png, image/gif, or image/webp"})
		return
	}

	// Generate unique S3 key for category image
	ext := filepath.Ext(req.FileName)
	if ext == "" {
		ext = getExtensionFromContentType(req.ContentType)
	}
	uniqueID := uuid.New().String()
	objectKey := fmt.Sprintf("%s/%d/image/%s%s", h.s3BasePath, categoryID, uniqueID, ext)

	// Generate presigned URL (valid for 15 minutes)
	expiresIn := 15 * time.Minute
	uploadURL, err := h.s3Client.GeneratePresignedUploadURL(c.Request.Context(), objectKey, req.ContentType, expiresIn)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to generate upload URL"})
		return
	}

	c.JSON(http.StatusOK, ImageUploadURLResponse{
		UploadURL: uploadURL,
		ObjectKey: objectKey,
		PublicURL: h.s3Client.GetPublicURL(objectKey),
		ExpiresIn: int(expiresIn.Seconds()),
	})
}

// GetSubcategoryImageUploadURL godoc
// @Summary Get presigned URL for uploading a subcategory image
// @Tags subcategories
// @Accept json
// @Produce json
// @Param id path int true "Subcategory ID"
// @Param file_name query string true "File name"
// @Param content_type query string true "Content type (e.g., image/jpeg)"
// @Success 200 {object} ImageUploadURLResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /subcategories/{id}/image/upload-url [get]
func (h *CategoryHandler) GetSubcategoryImageUploadURL(c *gin.Context) {
	subcategoryID, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	var req ImageUploadURLRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	// Validate content type
	if !isValidImageContentType(req.ContentType) {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid content type, must be image/jpeg, image/png, image/gif, or image/webp"})
		return
	}

	// Generate unique S3 key for subcategory image
	// Subcategories use their own top-level folder: admin-panel/subcategories/{id}/image/
	// NOT under admin-panel/categories/subcategories/ (which was a path mismatch bug)
	ext := filepath.Ext(req.FileName)
	if ext == "" {
		ext = getExtensionFromContentType(req.ContentType)
	}
	uniqueID := uuid.New().String()
	objectKey := fmt.Sprintf("admin-panel/subcategories/%d/image/%s%s", subcategoryID, uniqueID, ext)

	// Generate presigned URL (valid for 15 minutes)
	expiresIn := 15 * time.Minute
	uploadURL, err := h.s3Client.GeneratePresignedUploadURL(c.Request.Context(), objectKey, req.ContentType, expiresIn)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to generate upload URL"})
		return
	}

	c.JSON(http.StatusOK, ImageUploadURLResponse{
		UploadURL: uploadURL,
		ObjectKey: objectKey,
		PublicURL: h.s3Client.GetPublicURL(objectKey),
		ExpiresIn: int(expiresIn.Seconds()),
	})
}
