// Package handler provides HTTP handlers for the catalog service.
package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/service"
)

// ProductHandler handles HTTP requests for products.
type ProductHandler struct {
	productService *service.ProductService
}

// NewProductHandler creates a new product handler.
func NewProductHandler(productService *service.ProductService) *ProductHandler {
	return &ProductHandler{productService: productService}
}

// RegisterRoutes registers product routes.
func (h *ProductHandler) RegisterRoutes(r *gin.RouterGroup) {
	products := r.Group("/products")
	{
		products.GET("", h.ListProducts)
		products.POST("", h.CreateProduct)
		products.GET("/:id", h.GetProduct)
		products.PUT("/:id", h.UpdateProduct)
		products.DELETE("/:id", h.ArchiveProduct)
		products.DELETE("/:id/permanent", h.DeleteProduct)
		products.POST("/:id/unarchive", h.UnarchiveProduct)

		// Variant-specific endpoints
		products.GET("/:id/children", h.GetChildren)
		products.POST("/:id/children", h.CreateChildProduct)
		products.POST("/:id/sync-aggregates", h.SyncParentAggregates)
		products.PUT("/:id/default-variant", h.SetDefaultVariant)
		products.POST("/:id/generate-variants", h.GenerateVariants)
		products.PUT("/:id/bulk-update-variants", h.BulkUpdateVariants)
	}
}

// ListProducts handles GET /products
func (h *ProductHandler) ListProducts(c *gin.Context) {
	pagination := parsePagination(c)
	filter := parseProductFilter(c)
	sort := parseProductSort(c)

	result, err := h.productService.ListProducts(c.Request.Context(), filter, pagination, &sort)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toPaginatedProductsResponse(result))
}

// CreateProduct handles POST /products
func (h *ProductHandler) CreateProduct(c *gin.Context) {
	var req CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	input := req.toInput()
	result, err := h.productService.CreateProduct(c.Request.Context(), input)
	if err != nil {
		statusCode := http.StatusInternalServerError
		if isDomainError(err) {
			statusCode = http.StatusBadRequest
		}
		c.JSON(statusCode, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toProductWithRelationsResponse(result))
}

// GetProduct handles GET /products/:id
func (h *ProductHandler) GetProduct(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	result, err := h.productService.GetProduct(c.Request.Context(), id)
	if err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toProductWithRelationsResponse(result))
}

// UpdateProduct handles PUT /products/:id
func (h *ProductHandler) UpdateProduct(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	var req UpdateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	input := req.toInput(id)
	result, err := h.productService.UpdateProduct(c.Request.Context(), input)
	if err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		if err == domain.ErrProductArchived {
			c.JSON(http.StatusBadRequest, ErrorResponse{Error: "cannot update archived product"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toProductWithRelationsResponse(result))
}

// ArchiveProduct handles DELETE /products/:id (soft delete)
func (h *ProductHandler) ArchiveProduct(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	if err := h.productService.ArchiveProduct(c.Request.Context(), id); err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "product archived successfully"})
}

// DeleteProduct handles DELETE /products/:id/permanent
// Permanently deletes a product and all associated data (images, attributes, category mappings, etc.).
func (h *ProductHandler) DeleteProduct(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	if err := h.productService.DeleteProduct(c.Request.Context(), id); err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "product permanently deleted"})
}

// UnarchiveProduct handles POST /products/:id/unarchive
func (h *ProductHandler) UnarchiveProduct(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	if err := h.productService.UnarchiveProduct(c.Request.Context(), id); err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "product unarchived successfully"})
}

// GetChildren handles GET /products/:id/children
func (h *ProductHandler) GetChildren(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	result, err := h.productService.GetParentWithChildren(c.Request.Context(), id)
	if err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, toProductWithRelationsResponse(result))
}

// CreateChildProduct handles POST /products/:id/children
func (h *ProductHandler) CreateChildProduct(c *gin.Context) {
	parentID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid parent id"})
		return
	}

	var req CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	input := req.toInput()
	result, err := h.productService.CreateChildProduct(c.Request.Context(), parentID, input)
	if err != nil {
		statusCode := http.StatusInternalServerError
		if isDomainError(err) {
			statusCode = http.StatusBadRequest
		}
		c.JSON(statusCode, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toProductWithRelationsResponse(result))
}

// SyncParentAggregates handles POST /products/:id/sync-aggregates
func (h *ProductHandler) SyncParentAggregates(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	if err := h.productService.SyncParentAggregates(c.Request.Context(), id); err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "parent aggregates synced successfully"})
}

// SetDefaultVariant handles PUT /products/:id/default-variant
func (h *ProductHandler) SetDefaultVariant(c *gin.Context) {
	childID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid child id"})
		return
	}

	if err := h.productService.SetDefaultVariant(c.Request.Context(), childID); err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "default variant updated successfully"})
}

// GenerateVariantsRequest is the request body for generating variants.
type GenerateVariantsRequest struct {
	DefaultPrice float64 `json:"default_price"`
	DefaultStock int32   `json:"default_stock"`
	SkipExisting bool    `json:"skip_existing"`
}

// GenerateVariantsResponse is the response body for generating variants.
type GenerateVariantsResponse struct {
	Created       int     `json:"created"`
	Skipped       int     `json:"skipped"`
	TotalPossible int     `json:"total_possible"`
	Variants      []int32 `json:"variants"`
}

// GenerateVariants handles POST /products/:id/generate-variants
func (h *ProductHandler) GenerateVariants(c *gin.Context) {
	parentID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid parent id"})
		return
	}

	var req GenerateVariantsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	// Set defaults if not provided
	if req.DefaultPrice == 0 {
		req.DefaultPrice = 0
	}
	if req.DefaultStock == 0 {
		req.DefaultStock = 0
	}

	input := &service.GenerateVariantsInput{
		DefaultPrice: req.DefaultPrice,
		DefaultStock: req.DefaultStock,
		SkipExisting: req.SkipExisting,
	}

	result, err := h.productService.GenerateVariants(c.Request.Context(), parentID, input)
	if err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		statusCode := http.StatusInternalServerError
		if isDomainError(err) {
			statusCode = http.StatusBadRequest
		}
		c.JSON(statusCode, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, GenerateVariantsResponse{
		Created:       result.Created,
		Skipped:       result.Skipped,
		TotalPossible: result.TotalPossible,
		Variants:      result.Variants,
	})
}

// BulkUpdateVariantsRequest is the request body for bulk updating variants.
type BulkUpdateVariantsRequest struct {
	VariantIDs []int32  `json:"variant_ids" binding:"required,min=1"`
	Price      *float64 `json:"price"`
	Stock      *int32   `json:"stock"`
	IsActive   *bool    `json:"is_active"`
}

// BulkUpdateVariants handles PUT /products/:id/bulk-update-variants
func (h *ProductHandler) BulkUpdateVariants(c *gin.Context) {
	parentID, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid parent id"})
		return
	}

	var req BulkUpdateVariantsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	input := &service.BulkUpdateVariantsInput{
		VariantIDs: req.VariantIDs,
		Price:      req.Price,
		Stock:      req.Stock,
		IsActive:   req.IsActive,
	}

	if err := h.productService.BulkUpdateVariants(c.Request.Context(), parentID, input); err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		statusCode := http.StatusInternalServerError
		if isDomainError(err) {
			statusCode = http.StatusBadRequest
		}
		c.JSON(statusCode, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "variants updated successfully"})
}

// Helper functions
func parseID(c *gin.Context, param string) (int32, error) {
	idStr := c.Param(param)
	id, err := strconv.ParseInt(idStr, 10, 32)
	if err != nil {
		return 0, err
	}
	return int32(id), nil
}

func parsePagination(c *gin.Context) repository.Pagination {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	return repository.Pagination{Page: page, PageSize: pageSize}
}

func parseProductFilter(c *gin.Context) *domain.ProductFilter {
	filter := &domain.ProductFilter{}

	if storeID := c.Query("store_id"); storeID != "" {
		if id, err := strconv.ParseInt(storeID, 10, 32); err == nil {
			sid := int32(id)
			filter.StoreID = &sid
		}
	}

	if ownerOrgID := c.Query("owner_org_id"); ownerOrgID != "" {
		filter.OwnerOrgID = &ownerOrgID
	}

	if productType := c.Query("product_type"); productType != "" {
		pt := domain.ProductType(productType)
		filter.ProductType = &pt
	}

	if visibility := c.Query("visibility"); visibility != "" {
		v := domain.ProductVisibility(visibility)
		filter.Visibility = &v
	}

	if isActive := c.Query("is_active"); isActive != "" {
		active := isActive == "true"
		filter.IsActive = &active
	}

	if isFeatured := c.Query("is_featured"); isFeatured != "" {
		featured := isFeatured == "true"
		filter.IsFeatured = &featured
	}

	if isArchived := c.Query("is_archived"); isArchived != "" {
		archived := isArchived == "true"
		filter.IsArchived = &archived
	} else {
		// Default to non-archived
		archived := false
		filter.IsArchived = &archived
	}

	if parentID := c.Query("parent_id"); parentID != "" {
		if id, err := strconv.ParseInt(parentID, 10, 32); err == nil {
			pid := int32(id)
			filter.ParentID = &pid
		}
	}

	if categoryID := c.Query("category_id"); categoryID != "" {
		if id, err := strconv.ParseInt(categoryID, 10, 32); err == nil {
			cid := int32(id)
			filter.CategoryID = &cid
		}
	}

	if subcategoryID := c.Query("subcategory_id"); subcategoryID != "" {
		if id, err := strconv.ParseInt(subcategoryID, 10, 32); err == nil {
			sid := int32(id)
			filter.SubcategoryID = &sid
		}
	}

	if collectionID := c.Query("collection_id"); collectionID != "" {
		if id, err := strconv.ParseInt(collectionID, 10, 32); err == nil {
			cid := int32(id)
			filter.CollectionID = &cid
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

	if search := c.Query("search"); search != "" {
		filter.Search = &search
	}

	if minPrice := c.Query("min_price"); minPrice != "" {
		if price, err := strconv.ParseFloat(minPrice, 64); err == nil {
			filter.MinPrice = &price
		}
	}

	if maxPrice := c.Query("max_price"); maxPrice != "" {
		if price, err := strconv.ParseFloat(maxPrice, 64); err == nil {
			filter.MaxPrice = &price
		}
	}

	return filter
}

func parseProductSort(c *gin.Context) domain.ProductSort {
	return domain.ProductSort{
		Field:     c.DefaultQuery("sort_field", "created_at"),
		Direction: c.DefaultQuery("sort_direction", "desc"),
	}
}

func isDomainError(err error) bool {
	switch err {
	case domain.ErrChildMustHaveParent,
		domain.ErrParentCannotHaveParent,
		domain.ErrChildCannotBeVisible,
		domain.ErrStandardCannotHaveParent,
		domain.ErrProductArchived,
		domain.ErrDuplicateSKU,
		domain.ErrNoVariantOptions,
		domain.ErrNotParentProduct,
		domain.ErrVariantNotBelongToParent:
		return true
	}
	return false
}
