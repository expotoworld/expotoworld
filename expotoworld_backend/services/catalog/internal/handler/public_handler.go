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

// PublicHandler handles read-only HTTP requests for the consumer-facing app.
// These endpoints require authentication but NOT admin role.
// They filter data to only return active, non-archived items and exclude
// admin-only fields like cost_price and owner_org_id.
type PublicHandler struct {
	productService  *service.ProductService
	categoryService *service.CategoryService
	storeService    *service.StoreService
}

// NewPublicHandler creates a new public handler.
func NewPublicHandler(
	productService *service.ProductService,
	categoryService *service.CategoryService,
	storeService *service.StoreService,
) *PublicHandler {
	return &PublicHandler{
		productService:  productService,
		categoryService: categoryService,
		storeService:    storeService,
	}
}

// RegisterRoutes registers public read-only routes.
func (h *PublicHandler) RegisterRoutes(r *gin.RouterGroup) {
	// Store endpoints
	r.GET("/stores", h.ListStores)
	r.GET("/stores/:id", h.GetStore)

	// Category endpoints
	r.GET("/categories", h.ListCategories)
	r.GET("/categories/tree", h.GetCategoryTree)
	r.GET("/categories/tree/full", h.GetCategoryTreeFull)
	r.GET("/categories/:id", h.GetCategory)
	r.GET("/categories/:id/subcategories", h.ListSubcategories)

	// Collection endpoints
	r.GET("/subcategories/:id/collections", h.ListCollections)

	// Product endpoints
	r.GET("/products", h.ListProducts)
	r.GET("/products/:id", h.GetProduct)
	r.GET("/products/:id/children", h.GetProductChildren)
}

// ============================================================
// Public Response DTOs (exclude admin-only fields)
// ============================================================

// PublicProductResponse is a consumer-facing product response.
// It excludes admin fields: cost_price, owner_org_id, shelf_code, logistics_*
type PublicProductResponse struct {
	ProductID               int32                      `json:"product_id"`
	ProductUUID             string                     `json:"product_uuid"`
	SKU                     *string                    `json:"sku"`
	Title                   *string                    `json:"title"`
	Description             *string                    `json:"description"`
	StoreID                 *int32                     `json:"store_id"`
	MainPrice               *float64                   `json:"main_price"`
	StrikethroughPrice      *float64                   `json:"strikethrough_price"`
	TaxRate                 *float64                   `json:"tax_rate"`
	StockLeft               *int32                     `json:"stock_left"`
	MinimumOrderQuantity    *int32                     `json:"minimum_order_quantity"`
	NetContent              *float64                   `json:"net_content"`
	ContentUnit             *string                    `json:"content_unit"`
	ReferencePrice          *float64                   `json:"reference_price"`
	ReferenceUnit           *string                    `json:"reference_unit"`
	IsActive                bool                       `json:"is_active"`
	IsFeatured              bool                       `json:"is_featured"`
	IsMiniAppRecommendation bool                       `json:"is_mini_app_recommendation"`
	ProductType             string                     `json:"product_type"`
	ParentID                *int32                     `json:"parent_id"`
	Visibility              string                     `json:"visibility"`
	IsDefaultVariant        bool                       `json:"is_default_variant"`
	PriceMin                *float64                   `json:"price_min"`
	PriceMax                *float64                   `json:"price_max"`
	StockTotal              *int32                     `json:"stock_total"`
	VariantOptionsIndex     map[string][]VariantOption `json:"variant_options_index"`
	ETWStoreType            *string                    `json:"etw_store_type"`
	ETWMiniAppType          *string                    `json:"etw_mini_app_type"`
	PrimaryImageURL         *string                    `json:"primary_image_url"`
	CreatedAt               string                     `json:"created_at"`
	UpdatedAt               string                     `json:"updated_at"`
}

// PublicProductWithRelationsResponse includes product with relations (no admin fields).
type PublicProductWithRelationsResponse struct {
	PublicProductResponse
	Attributes     []AttributeResponse     `json:"attributes"`
	Specifications []SpecificationResponse `json:"specifications"`
	Images         []ImageResponse         `json:"images"`
	Categories     []CategoryResponse      `json:"categories"`
	Subcategories  []SubcategoryResponse   `json:"subcategories,omitempty"`
	Collections    []CollectionResponse    `json:"collections,omitempty"`
	Children       []PublicProductResponse `json:"children,omitempty"`
}

// PaginatedPublicProductsResponse paginates public products.
type PaginatedPublicProductsResponse struct {
	Items      []PublicProductResponse `json:"items"`
	TotalCount int64                   `json:"total_count"`
	Page       int                     `json:"page"`
	PageSize   int                     `json:"page_size"`
	TotalPages int                     `json:"total_pages"`
}

// toPublicProductResponse converts a domain product to a public response (no admin fields).
func toPublicProductResponse(p *domain.Product) PublicProductResponse {
	resp := PublicProductResponse{
		ProductID:               p.ProductID,
		ProductUUID:             p.ProductUUID,
		SKU:                     p.SKU,
		Title:                   p.Title,
		Description:             p.Description,
		StoreID:                 p.StoreID,
		MainPrice:               p.MainPrice,
		StrikethroughPrice:      p.StrikethroughPrice,
		TaxRate:                 p.TaxRate,
		StockLeft:               p.StockLeft,
		MinimumOrderQuantity:    p.MinimumOrderQuantity,
		NetContent:              p.NetContent,
		ContentUnit:             p.ContentUnit,
		ReferencePrice:          p.ReferencePrice,
		ReferenceUnit:           p.ReferenceUnit,
		IsActive:                p.IsActive,
		IsFeatured:              p.IsFeatured,
		IsMiniAppRecommendation: p.IsMiniAppRecommendation,
		ProductType:             string(p.ProductType),
		ParentID:                p.ParentID,
		Visibility:              string(p.Visibility),
		IsDefaultVariant:        p.IsDefaultVariant,
		PriceMin:                p.PriceMin,
		PriceMax:                p.PriceMax,
		StockTotal:              p.StockTotal,
		PrimaryImageURL:         p.PrimaryImageURL,
		CreatedAt:               p.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:               p.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	if p.ETWStoreType != nil {
		s := string(*p.ETWStoreType)
		resp.ETWStoreType = &s
	}
	if p.ETWMiniAppType != nil {
		s := string(*p.ETWMiniAppType)
		resp.ETWMiniAppType = &s
	}

	// Convert variant options index
	if p.VariantOptionsIndex != nil {
		resp.VariantOptionsIndex = make(map[string][]VariantOption)
		for key, values := range p.VariantOptionsIndex {
			for _, v := range values {
				resp.VariantOptionsIndex[key] = append(resp.VariantOptionsIndex[key], VariantOption{
					Value:        v.Value,
					DisplayOrder: v.DisplayOrder,
				})
			}
		}
	}

	return resp
}

// toPublicProductWithRelationsResponse converts a domain product with relations to a public response.
func toPublicProductWithRelationsResponse(p *domain.ProductWithRelations) *PublicProductWithRelationsResponse {
	resp := &PublicProductWithRelationsResponse{
		PublicProductResponse: toPublicProductResponse(&p.Product),
	}

	for _, attr := range p.Attributes {
		resp.Attributes = append(resp.Attributes, AttributeResponse{
			AttributeID:    attr.AttributeID,
			ProductID:      attr.ProductID,
			AttributeName:  attr.AttributeName,
			AttributeValue: attr.AttributeValue,
			DisplayOrder:   attr.DisplayOrder,
			CreatedAt:      attr.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	for _, spec := range p.Specifications {
		resp.Specifications = append(resp.Specifications, SpecificationResponse{
			SpecificationID: spec.SpecificationID,
			ProductID:       spec.ProductID,
			SpecName:        spec.SpecName,
			SpecValue:       spec.SpecValue,
			DisplayOrder:    spec.DisplayOrder,
			CreatedAt:       spec.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	for _, img := range p.Images {
		resp.Images = append(resp.Images, ImageResponse{
			ImageID:      img.ImageID,
			ProductID:    img.ProductID,
			ImageURL:     img.ImageURL,
			DisplayOrder: img.DisplayOrder,
			IsPrimary:    img.IsPrimary,
			CreatedAt:    img.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	for _, cat := range p.Categories {
		resp.Categories = append(resp.Categories, *toCategoryResponse(&cat))
	}

	for _, child := range p.Children {
		resp.Children = append(resp.Children, toPublicProductResponse(&child))
	}

	return resp
}

func toPaginatedPublicProductsResponse(result *repository.PaginatedResult[domain.Product]) *PaginatedPublicProductsResponse {
	resp := &PaginatedPublicProductsResponse{
		TotalCount: result.TotalCount,
		Page:       result.Page,
		PageSize:   result.PageSize,
		TotalPages: result.TotalPages,
	}
	for _, p := range result.Items {
		resp.Items = append(resp.Items, toPublicProductResponse(&p))
	}
	return resp
}

// ============================================================
// Public Endpoint Handlers
// ============================================================

// ListStores handles GET /public/stores
// Returns only active stores with search and filter support.
func (h *PublicHandler) ListStores(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	filter := h.parseStoreFilter(c)
	// Force active-only for public endpoints
	active := true
	filter.IsActive = &active

	pagination := repository.Pagination{Page: page, PageSize: pageSize}
	result, err := h.storeService.ListStoresFiltered(c.Request.Context(), filter, pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to list stores"})
		return
	}

	c.JSON(http.StatusOK, toPaginatedStoresResponse(result))
}

// GetStore handles GET /public/stores/:id
// Returns a single store (only if active).
func (h *PublicHandler) GetStore(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid store id"})
		return
	}

	store, err := h.storeService.GetStore(c.Request.Context(), int32(id))
	if err != nil {
		if err == domain.ErrStoreNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "store not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to get store"})
		return
	}

	// Only return active stores
	if !store.IsActive {
		c.JSON(http.StatusNotFound, ErrorResponse{Error: "store not found"})
		return
	}

	c.JSON(http.StatusOK, toStoreResponse(store))
}

// ListCategories handles GET /public/categories
// Returns only active categories with filters.
func (h *PublicHandler) ListCategories(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "50"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 50
	}

	filter := parseCategoryFilter(c)
	// Force active-only for public endpoints
	active := true
	filter.IsActive = &active

	pagination := repository.Pagination{Page: page, PageSize: pageSize}
	result, err := h.categoryService.ListCategories(c.Request.Context(), filter, pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to list categories"})
		return
	}

	c.JSON(http.StatusOK, toPaginatedCategoriesResponse(result))
}

// GetCategoryTree handles GET /public/categories/tree
// Returns categories with nested subcategories (active only).
func (h *PublicHandler) GetCategoryTree(c *gin.Context) {
	filter := parseCategoryFilter(c)
	// Force active-only for public endpoints
	active := true
	filter.IsActive = &active

	tree, err := h.categoryService.GetCategoryTree(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to get category tree"})
		return
	}

	// Filter out inactive subcategories
	var filtered []domain.CategoryWithSubcategories
	for _, cat := range tree {
		var activeSubs []domain.Subcategory
		for _, sub := range cat.Subcategories {
			if sub.IsActive {
				activeSubs = append(activeSubs, sub)
			}
		}
		cat.Subcategories = activeSubs
		filtered = append(filtered, cat)
	}

	c.JSON(http.StatusOK, toCategoryTreeResponse(filtered))
}

// GetCategory handles GET /public/categories/:id
func (h *PublicHandler) GetCategory(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	cat, err := h.categoryService.GetCategoryWithSubcategories(c.Request.Context(), int32(id))
	if err != nil {
		if err == domain.ErrCategoryNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "category not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to get category"})
		return
	}

	if !cat.Category.IsActive {
		c.JSON(http.StatusNotFound, ErrorResponse{Error: "category not found"})
		return
	}

	// Filter to active subcategories only
	var activeSubs []domain.Subcategory
	for _, sub := range cat.Subcategories {
		if sub.IsActive {
			activeSubs = append(activeSubs, sub)
		}
	}
	cat.Subcategories = activeSubs

	c.JSON(http.StatusOK, toCategoryWithSubcategoriesResponse(cat))
}

// ListSubcategories handles GET /public/categories/:id/subcategories
func (h *PublicHandler) ListSubcategories(c *gin.Context) {
	categoryID, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid category id"})
		return
	}

	subcategories, err := h.categoryService.GetSubcategoriesByCategory(c.Request.Context(), int32(categoryID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to list subcategories"})
		return
	}

	// Filter to active only
	var active []domain.Subcategory
	for _, s := range subcategories {
		if s.IsActive {
			active = append(active, s)
		}
	}

	c.JSON(http.StatusOK, toSubcategoriesResponse(active))
}

// ListProducts handles GET /public/products
// Returns only active, non-archived, visible products.
func (h *PublicHandler) ListProducts(c *gin.Context) {
	pagination := parsePagination(c)
	filter := parseProductFilter(c)
	sort := parseProductSort(c)

	// Force public-only filters
	active := true
	filter.IsActive = &active
	archived := false
	filter.IsArchived = &archived
	visible := domain.ProductVisibilityVisible
	filter.Visibility = &visible

	result, err := h.productService.ListProducts(c.Request.Context(), filter, pagination, &sort)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to list products"})
		return
	}

	c.JSON(http.StatusOK, toPaginatedPublicProductsResponse(result))
}

// GetProduct handles GET /public/products/:id
// Returns a single product with full relations (if active and visible).
func (h *PublicHandler) GetProduct(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	product, err := h.productService.GetProduct(c.Request.Context(), int32(id))
	if err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to get product"})
		return
	}

	// Enforce public access: only active, non-archived products
	if !product.Product.IsActive || product.Product.IsArchived {
		c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
		return
	}

	c.JSON(http.StatusOK, toPublicProductWithRelationsResponse(product))
}

// GetProductChildren handles GET /public/products/:id/children
// Returns child variants for a parent product.
func (h *PublicHandler) GetProductChildren(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product id"})
		return
	}

	result, err := h.productService.GetParentWithChildren(c.Request.Context(), int32(id))
	if err != nil {
		if err == domain.ErrProductNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to get product children"})
		return
	}

	// Enforce public access: only active parent
	if !result.Product.IsActive || result.Product.IsArchived {
		c.JSON(http.StatusNotFound, ErrorResponse{Error: "product not found"})
		return
	}

	// Filter to active children only, return public DTOs
	var activeChildren []PublicProductResponse
	for _, child := range result.Children {
		if child.IsActive && !child.IsArchived {
			activeChildren = append(activeChildren, toPublicProductResponse(&child))
		}
	}

	c.JSON(http.StatusOK, activeChildren)
}

// GetCategoryTreeFull handles GET /public/categories/tree/full
// Returns categories with nested subcategories and collections (active only).
func (h *PublicHandler) GetCategoryTreeFull(c *gin.Context) {
	filter := parseCategoryFilter(c)
	active := true
	filter.IsActive = &active

	tree, err := h.categoryService.GetCategoryTreeFull(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to get category tree"})
		return
	}

	// Filter out inactive subcategories and inactive collections
	var filtered []domain.CategoryWithFullHierarchy
	for _, cat := range tree {
		var activeSubs []domain.SubcategoryWithCollections
		for _, sub := range cat.Subcategories {
			if sub.IsActive {
				var activeColls []domain.Collection
				for _, coll := range sub.Collections {
					if coll.IsActive {
						activeColls = append(activeColls, coll)
					}
				}
				sub.Collections = activeColls
				activeSubs = append(activeSubs, sub)
			}
		}
		cat.Subcategories = activeSubs
		filtered = append(filtered, cat)
	}

	c.JSON(http.StatusOK, toCategoryTreeFullResponse(filtered))
}

// ListCollections handles GET /public/subcategories/:id/collections
// Returns only active collections for a subcategory.
func (h *PublicHandler) ListCollections(c *gin.Context) {
	subcategoryID, err := strconv.ParseInt(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid subcategory id"})
		return
	}

	collections, err := h.categoryService.GetCollectionsBySubcategory(c.Request.Context(), int32(subcategoryID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: "failed to list collections"})
		return
	}

	// Filter to active only
	var active []domain.Collection
	for _, coll := range collections {
		if coll.IsActive {
			active = append(active, coll)
		}
	}

	c.JSON(http.StatusOK, toCollectionsResponse(active))
}

// ============================================================
// Filter Helpers
// ============================================================

func (h *PublicHandler) parseStoreFilter(c *gin.Context) *domain.StoreFilter {
	filter := &domain.StoreFilter{}

	if regionID := c.Query("region_id"); regionID != "" {
		if id, err := strconv.ParseInt(regionID, 10, 32); err == nil {
			rid := int32(id)
			filter.RegionID = &rid
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

	return filter
}
