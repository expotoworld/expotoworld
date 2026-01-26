// Package handler provides HTTP handlers for the catalog service.
package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
)

// SpecificationHandler handles HTTP requests for product specifications.
type SpecificationHandler struct {
	specRepo repository.SpecificationRepository
}

// NewSpecificationHandler creates a new specification handler.
func NewSpecificationHandler(specRepo repository.SpecificationRepository) *SpecificationHandler {
	return &SpecificationHandler{specRepo: specRepo}
}

// RegisterRoutes registers specification routes.
func (h *SpecificationHandler) RegisterRoutes(r *gin.RouterGroup) {
	specs := r.Group("/specifications")
	{
		specs.GET("", h.GetByProductID)                 // GET /specifications?product_id=X
		specs.POST("", h.Create)                        // POST /specifications
		specs.PUT("/:id", h.Update)                     // PUT /specifications/:id
		specs.DELETE("/:id", h.Delete)                  // DELETE /specifications/:id
		specs.POST("/batch", h.BatchCreate)             // POST /specifications/batch
		specs.PUT("/replace/:product_id", h.ReplaceAll) // PUT /specifications/replace/:product_id
	}
}

// CreateSpecificationRequest represents a request to create a specification.
type CreateSpecificationRequest struct {
	ProductID    int32  `json:"product_id" binding:"required"`
	SpecName     string `json:"spec_name" binding:"required"`
	SpecValue    string `json:"spec_value" binding:"required"`
	DisplayOrder int32  `json:"display_order"`
}

// UpdateSpecificationRequest represents a request to update a specification.
type UpdateSpecificationRequest struct {
	SpecName     string `json:"spec_name"`
	SpecValue    string `json:"spec_value"`
	DisplayOrder *int32 `json:"display_order"`
}

// BatchCreateSpecificationRequest represents a request to create multiple specifications.
type BatchCreateSpecificationRequest struct {
	ProductID      int32                        `json:"product_id" binding:"required"`
	Specifications []CreateSpecificationRequest `json:"specifications" binding:"required"`
}

// ReplaceAllSpecificationsRequest represents a request to replace all specifications.
type ReplaceAllSpecificationsRequest struct {
	Specifications []CreateSpecificationRequest `json:"specifications" binding:"required"`
}

// GetByProductID handles GET /specifications?product_id=X
func (h *SpecificationHandler) GetByProductID(c *gin.Context) {
	productIDStr := c.Query("product_id")
	if productIDStr == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "product_id is required"})
		return
	}

	productID, err := parseIntParam(productIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product_id"})
		return
	}

	specs, err := h.specRepo.GetByProductID(c.Request.Context(), productID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	var resp []SpecificationResponse
	for _, spec := range specs {
		resp = append(resp, SpecificationResponse{
			SpecificationID: spec.SpecificationID,
			ProductID:       spec.ProductID,
			SpecName:        spec.SpecName,
			SpecValue:       spec.SpecValue,
			DisplayOrder:    spec.DisplayOrder,
			CreatedAt:       spec.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	c.JSON(http.StatusOK, resp)
}

// Create handles POST /specifications
func (h *SpecificationHandler) Create(c *gin.Context) {
	var req CreateSpecificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	params := &domain.CreateSpecificationParams{
		ProductID:    req.ProductID,
		SpecName:     req.SpecName,
		SpecValue:    req.SpecValue,
		DisplayOrder: req.DisplayOrder,
	}

	spec, err := h.specRepo.Create(c.Request.Context(), params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusCreated, SpecificationResponse{
		SpecificationID: spec.SpecificationID,
		ProductID:       spec.ProductID,
		SpecName:        spec.SpecName,
		SpecValue:       spec.SpecValue,
		DisplayOrder:    spec.DisplayOrder,
		CreatedAt:       spec.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	})
}

// Update handles PUT /specifications/:id
func (h *SpecificationHandler) Update(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid specification id"})
		return
	}

	var req UpdateSpecificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	params := &domain.UpdateSpecificationParams{
		SpecName:     &req.SpecName,
		SpecValue:    &req.SpecValue,
		DisplayOrder: req.DisplayOrder,
	}

	if err := h.specRepo.Update(c.Request.Context(), id, params); err != nil {
		if err == domain.ErrSpecificationNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "specification not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	// Fetch updated spec
	spec, err := h.specRepo.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, SpecificationResponse{
		SpecificationID: spec.SpecificationID,
		ProductID:       spec.ProductID,
		SpecName:        spec.SpecName,
		SpecValue:       spec.SpecValue,
		DisplayOrder:    spec.DisplayOrder,
		CreatedAt:       spec.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	})
}

// Delete handles DELETE /specifications/:id
func (h *SpecificationHandler) Delete(c *gin.Context) {
	id, err := parseID(c, "id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid specification id"})
		return
	}

	if err := h.specRepo.Delete(c.Request.Context(), id); err != nil {
		if err == domain.ErrSpecificationNotFound {
			c.JSON(http.StatusNotFound, ErrorResponse{Error: "specification not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}

// BatchCreate handles POST /specifications/batch
func (h *SpecificationHandler) BatchCreate(c *gin.Context) {
	var req BatchCreateSpecificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	var params []domain.CreateSpecificationParams
	for _, spec := range req.Specifications {
		params = append(params, domain.CreateSpecificationParams{
			ProductID:    req.ProductID,
			SpecName:     spec.SpecName,
			SpecValue:    spec.SpecValue,
			DisplayOrder: spec.DisplayOrder,
		})
	}

	specs, err := h.specRepo.BulkCreate(c.Request.Context(), req.ProductID, params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	var resp []SpecificationResponse
	for _, spec := range specs {
		resp = append(resp, SpecificationResponse{
			SpecificationID: spec.SpecificationID,
			ProductID:       spec.ProductID,
			SpecName:        spec.SpecName,
			SpecValue:       spec.SpecValue,
			DisplayOrder:    spec.DisplayOrder,
			CreatedAt:       spec.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	c.JSON(http.StatusCreated, resp)
}

// ReplaceAll handles PUT /specifications/replace/:product_id
func (h *SpecificationHandler) ReplaceAll(c *gin.Context) {
	productID, err := parseID(c, "product_id")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: "invalid product_id"})
		return
	}

	var req ReplaceAllSpecificationsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{Error: err.Error()})
		return
	}

	var params []domain.CreateSpecificationParams
	for _, spec := range req.Specifications {
		params = append(params, domain.CreateSpecificationParams{
			ProductID:    productID,
			SpecName:     spec.SpecName,
			SpecValue:    spec.SpecValue,
			DisplayOrder: spec.DisplayOrder,
		})
	}

	specs, err := h.specRepo.ReplaceAll(c.Request.Context(), productID, params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
		return
	}

	var resp []SpecificationResponse
	for _, spec := range specs {
		resp = append(resp, SpecificationResponse{
			SpecificationID: spec.SpecificationID,
			ProductID:       spec.ProductID,
			SpecName:        spec.SpecName,
			SpecValue:       spec.SpecValue,
			DisplayOrder:    spec.DisplayOrder,
			CreatedAt:       spec.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	c.JSON(http.StatusOK, resp)
}

// parseIntParam parses an int32 from a string parameter.
func parseIntParam(s string) (int32, error) {
	var id int32
	_, err := parseIntToValue(s, &id)
	return id, err
}

func parseIntToValue(s string, v *int32) (int32, error) {
	i, err := strconv.ParseInt(s, 10, 32)
	if err != nil {
		return 0, err
	}
	*v = int32(i)
	return *v, nil
}
