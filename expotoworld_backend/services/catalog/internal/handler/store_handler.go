package handler

import (
	"errors"
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"time"

	"github.com/expotoworld/expotoworld_backend/pkg/awsutil"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// StoreHandler handles HTTP requests for stores.
type StoreHandler struct {
	storeService *service.StoreService
	s3Client     *awsutil.S3Client
	s3BasePath   string // e.g., "admin-panel/stores"
}

// NewStoreHandler creates a new store handler.
func NewStoreHandler(storeService *service.StoreService, s3Client *awsutil.S3Client, s3BasePath string) *StoreHandler {
	return &StoreHandler{
		storeService: storeService,
		s3Client:     s3Client,
		s3BasePath:   s3BasePath,
	}
}

// RegisterRoutes registers store routes.
func (h *StoreHandler) RegisterRoutes(r *gin.RouterGroup) {
	stores := r.Group("/stores")
	{
		stores.GET("", h.ListStores)
		stores.POST("", h.CreateStore)
		stores.GET("/:id", h.GetStore)
		stores.PUT("/:id", h.UpdateStore)
		stores.DELETE("/:id", h.DeleteStore)
		stores.GET("/:id/regions", h.ListStoreRegions)
		stores.GET("/:id/image/upload-url", h.GetStoreImageUploadURL)
	}

	regions := r.Group("/regions")
	{
		regions.GET("", h.ListRegions)
		regions.POST("", h.CreateRegion)
		regions.GET("/:id", h.GetRegion)
		regions.PUT("/:id", h.UpdateRegion)
		regions.DELETE("/:id", h.DeleteRegion)
	}
}

// ListStores godoc
// @Summary List stores
// @Tags stores
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param page_size query int false "Page size" default(20)
// @Param search query string false "Search by name"
// @Param region_id query int false "Filter by region ID"
// @Param is_active query bool false "Filter by active status"
// @Param etw_store_type query string false "Filter by ETW store type"
// @Param etw_mini_app_type query string false "Filter by ETW mini app type"
// @Success 200 {object} PaginatedStoresResponse
// @Failure 500 {object} ErrorResponse
// @Router /stores [get]
func (h *StoreHandler) ListStores(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	filter := parseStoreFilter(c)
	pagination := repository.Pagination{Page: page, PageSize: pageSize}

	result, err := h.storeService.ListStoresFiltered(c.Request.Context(), filter, pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toPaginatedStoresResponse(result))
}

// GetStore godoc
// @Summary Get a store by ID
// @Tags stores
// @Accept json
// @Produce json
// @Param id path int true "Store ID"
// @Success 200 {object} StoreResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /stores/{id} [get]
func (h *StoreHandler) GetStore(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid store id"})
		return
	}

	store, err := h.storeService.GetStore(c.Request.Context(), int32(id))
	if err != nil {
		if errors.Is(err, domain.ErrStoreNotFound) {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toStoreResponse(store))
}

// CreateStore godoc
// @Summary Create a store
// @Tags stores
// @Accept json
// @Produce json
// @Param body body CreateStoreRequest true "Store data"
// @Success 201 {object} StoreResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /stores [post]
func (h *StoreHandler) CreateStore(c *gin.Context) {
	var req CreateStoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	store, err := h.storeService.CreateStore(c.Request.Context(), req.toParams())
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toStoreResponse(store))
}

// UpdateStore godoc
// @Summary Update a store
// @Tags stores
// @Accept json
// @Produce json
// @Param id path int true "Store ID"
// @Param body body UpdateStoreRequest true "Store data"
// @Success 200 {object} StoreResponse
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /stores/{id} [put]
func (h *StoreHandler) UpdateStore(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid store id"})
		return
	}

	var req UpdateStoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	store, err := h.storeService.UpdateStore(c.Request.Context(), int32(id), req.toParams())
	if err != nil {
		if errors.Is(err, domain.ErrStoreNotFound) {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toStoreResponse(store))
}

// DeleteStore godoc
// @Summary Delete a store
// @Tags stores
// @Accept json
// @Produce json
// @Param id path int true "Store ID"
// @Success 204
// @Failure 404 {object} ErrorResponse
// @Failure 409 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /stores/{id} [delete]
func (h *StoreHandler) DeleteStore(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid store id"})
		return
	}

	if err := h.storeService.DeleteStore(c.Request.Context(), int32(id)); err != nil {
		if errors.Is(err, domain.ErrStoreNotFound) {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: err.Error()})
			return
		}
		if errors.Is(err, domain.ErrStoreHasProducts) || errors.Is(err, domain.ErrStoreHasCategories) {
			c.JSON(http.StatusConflict, ErrorResponse{Error: err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// ListStoreRegions godoc
// @Summary List regions for a store
// @Tags stores
// @Accept json
// @Produce json
// @Param id path int true "Store ID"
// @Success 200 {array} RegionResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /stores/{id}/regions [get]
func (h *StoreHandler) ListStoreRegions(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid store id"})
		return
	}

	regions, err := h.storeService.ListRegionsByStore(c.Request.Context(), int32(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toRegionsResponse(regions))
}

// ListRegions godoc
// @Summary List all regions (paginated)
// @Tags regions
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param page_size query int false "Page size" default(20)
// @Param search query string false "Search by name or description"
// @Param store_id query int false "Filter by store ID"
// @Success 200 {object} PaginatedRegionsResponse
// @Failure 500 {object} ErrorResponse
// @Router /regions [get]
func (h *StoreHandler) ListRegions(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	filter := &domain.RegionFilter{}
	if search := c.Query("search"); search != "" {
		filter.Search = &search
	}
	if storeIDStr := c.Query("store_id"); storeIDStr != "" {
		if storeID, err := strconv.ParseInt(storeIDStr, 10, 32); err == nil {
			sid := int32(storeID)
			filter.StoreID = &sid
		}
	}

	result, err := h.storeService.ListRegionsPaginated(c.Request.Context(), filter, repository.Pagination{
		Page:     page,
		PageSize: pageSize,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toPaginatedRegionsResponse(result))
}

// GetRegion godoc
// @Summary Get a region by ID
// @Tags regions
// @Accept json
// @Produce json
// @Param id path int true "Region ID"
// @Success 200 {object} RegionResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /regions/{id} [get]
func (h *StoreHandler) GetRegion(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid region id"})
		return
	}

	region, err := h.storeService.GetRegion(c.Request.Context(), int32(id))
	if err != nil {
		if errors.Is(err, domain.ErrRegionNotFound) {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toRegionResponse(region))
}

// CreateRegion godoc
// @Summary Create a region
// @Tags regions
// @Accept json
// @Produce json
// @Param body body CreateRegionRequest true "Region data"
// @Success 201 {object} RegionResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /regions [post]
func (h *StoreHandler) CreateRegion(c *gin.Context) {
	var req CreateRegionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	region, err := h.storeService.CreateRegion(c.Request.Context(), req.toParams())
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toRegionResponse(region))
}

// UpdateRegion godoc
// @Summary Update a region
// @Tags regions
// @Accept json
// @Produce json
// @Param id path int true "Region ID"
// @Param body body UpdateRegionRequest true "Region data"
// @Success 200 {object} RegionResponse
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /regions/{id} [put]
func (h *StoreHandler) UpdateRegion(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid region id"})
		return
	}

	var req UpdateRegionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	region, err := h.storeService.UpdateRegion(c.Request.Context(), int32(id), req.toParams())
	if err != nil {
		if errors.Is(err, domain.ErrRegionNotFound) {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toRegionResponse(region))
}

// DeleteRegion godoc
// @Summary Delete a region
// @Tags regions
// @Accept json
// @Produce json
// @Param id path int true "Region ID"
// @Success 204
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /regions/{id} [delete]
func (h *StoreHandler) DeleteRegion(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid region id"})
		return
	}

	if err := h.storeService.DeleteRegion(c.Request.Context(), int32(id)); err != nil {
		if errors.Is(err, domain.ErrRegionNotFound) {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// StoreImageUploadURLRequest represents a request to get a presigned upload URL for a store image.
type StoreImageUploadURLRequest struct {
	FileName    string `form:"file_name" binding:"required"`
	ContentType string `form:"content_type" binding:"required"`
}

// StoreImageUploadURLResponse represents a response containing the presigned upload URL.
type StoreImageUploadURLResponse struct {
	UploadURL string `json:"upload_url"`
	ObjectKey string `json:"object_key"`
	PublicURL string `json:"public_url"`
	ExpiresIn int    `json:"expires_in"` // seconds
}

// GetStoreImageUploadURL godoc
// @Summary Get presigned URL for uploading a store image
// @Tags stores
// @Accept json
// @Produce json
// @Param id path int true "Store ID"
// @Param file_name query string true "File name"
// @Param content_type query string true "Content type (e.g., image/jpeg)"
// @Success 200 {object} StoreImageUploadURLResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /stores/{id}/image/upload-url [get]
func (h *StoreHandler) GetStoreImageUploadURL(c *gin.Context) {
	storeID, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid store id"})
		return
	}

	var req StoreImageUploadURLRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	// Validate content type
	if !isValidImageContentType(req.ContentType) {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid content type, must be image/jpeg, image/png, image/gif, or image/webp"})
		return
	}

	// Generate unique S3 key for store image
	ext := filepath.Ext(req.FileName)
	if ext == "" {
		ext = getExtensionFromContentType(req.ContentType)
	}
	uniqueID := uuid.New().String()
	objectKey := fmt.Sprintf("%s/%d/image/%s%s", h.s3BasePath, storeID, uniqueID, ext)

	// Generate presigned URL (valid for 15 minutes)
	expiresIn := 15 * time.Minute
	uploadURL, err := h.s3Client.GeneratePresignedUploadURL(c.Request.Context(), objectKey, req.ContentType, expiresIn)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to generate upload URL"})
		return
	}

	c.JSON(http.StatusOK, StoreImageUploadURLResponse{
		UploadURL: uploadURL,
		ObjectKey: objectKey,
		PublicURL: h.s3Client.GetPublicURL(objectKey),
		ExpiresIn: int(expiresIn.Seconds()),
	})
}

// parseStoreFilter extracts store filter parameters from query string.
func parseStoreFilter(c *gin.Context) *domain.StoreFilter {
	filter := &domain.StoreFilter{}

	if search := c.Query("search"); search != "" {
		filter.Search = &search
	}

	if regionID := c.Query("region_id"); regionID != "" {
		if id, err := strconv.ParseInt(regionID, 10, 32); err == nil {
			rid := int32(id)
			filter.RegionID = &rid
		}
	}

	if isActive := c.Query("is_active"); isActive != "" {
		if val, err := strconv.ParseBool(isActive); err == nil {
			filter.IsActive = &val
		}
	}

	if etwStoreType := c.Query("etw_store_type"); etwStoreType != "" {
		st := domain.ETWStoreType(etwStoreType)
		filter.ETWStoreType = &st
	}

	if etwMiniAppType := c.Query("etw_mini_app_type"); etwMiniAppType != "" {
		mt := domain.ETWMiniAppType(etwMiniAppType)
		filter.ETWMiniAppType = &mt
	}

	return filter
}
