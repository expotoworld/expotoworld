package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/service"
)

// CategoryHandler handles HTTP requests for categories and subcategories.
type CategoryHandler struct {
	categoryService *service.CategoryService
}

// NewCategoryHandler creates a new category handler.
func NewCategoryHandler(categoryService *service.CategoryService) *CategoryHandler {
	return &CategoryHandler{categoryService: categoryService}
}

// RegisterRoutes registers category routes.
func (h *CategoryHandler) RegisterRoutes(r *gin.RouterGroup) {
	categories := r.Group("/categories")
	{
		categories.GET("", h.ListCategories)
		categories.POST("", h.CreateCategory)
		categories.GET("/tree", h.GetCategoryTree)
		categories.GET("/:id", h.GetCategory)
		categories.PUT("/:id", h.UpdateCategory)
		categories.DELETE("/:id", h.DeleteCategory)
		categories.PUT("/reorder", h.ReorderCategories)

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
