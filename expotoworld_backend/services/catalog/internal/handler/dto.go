package handler

import (
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/service"
)

// ErrorResponse represents an error response.
type ErrorResponse struct {
	Error string `json:"error"`
}

// --------------------------------
// Product DTOs
// --------------------------------

// CreateProductRequest represents a request to create a product.
type CreateProductRequest struct {
	SKU                     string           `json:"sku" binding:"required"`
	Title                   string           `json:"title" binding:"required"`
	Description             *string          `json:"description"`
	StoreID                 int32            `json:"store_id" binding:"required"`
	OwnerOrgID              string           `json:"owner_org_id" binding:"required"` // UUID as string
	MainPrice               *float64         `json:"main_price"`
	StrikethroughPrice      *float64         `json:"strikethrough_price"`
	CostPrice               *float64         `json:"cost_price"`
	TaxRate                 *float64         `json:"tax_rate"`
	StockLeft               *int32           `json:"stock_left"`
	MinimumOrderQuantity    *int32           `json:"minimum_order_quantity"`
	NetContent              *float64         `json:"net_content"`
	ContentUnit             *string          `json:"content_unit"`
	ReferencePrice          *float64         `json:"reference_price"`
	ReferenceUnit           *string          `json:"reference_unit"`
	LogisticsLength         *float64         `json:"logistics_length"`
	LogisticsWidth          *float64         `json:"logistics_width"`
	LogisticsHeight         *float64         `json:"logistics_height"`
	LogisticsWeight         *float64         `json:"logistics_weight"`
	LogisticsVolume         *float64         `json:"logistics_volume"`
	ShelfCode               *string          `json:"shelf_code"`
	IsActive                bool             `json:"is_active"`
	IsFeatured              bool             `json:"is_featured"`
	IsMiniAppRecommendation bool             `json:"is_mini_app_recommendation"`
	ProductType             string           `json:"product_type" binding:"required"`
	ParentID                *int32           `json:"parent_id"`
	Visibility              string           `json:"visibility"`
	IsDefaultVariant        bool             `json:"is_default_variant"`
	ETWStoreType            *string          `json:"etw_store_type"`
	ETWMiniAppType          *string          `json:"etw_mini_app_type"`
	Attributes              []AttributeInput `json:"attributes"`
	Images                  []ImageInput     `json:"images"`
	CategoryIDs             []int32          `json:"category_ids"`
	SubcategoryIDs          []int32          `json:"subcategory_ids"`
}

// AttributeInput represents an attribute input.
type AttributeInput struct {
	AttributeName  string `json:"attribute_name" binding:"required"`
	AttributeValue string `json:"attribute_value" binding:"required"`
	DisplayOrder   int32  `json:"display_order"`
}

// ImageInput represents an image input.
type ImageInput struct {
	ImageURL     string `json:"image_url" binding:"required"`
	DisplayOrder int32  `json:"display_order"`
	IsPrimary    bool   `json:"is_primary"`
}

func (r *CreateProductRequest) toInput() *service.CreateProductInput {
	sku := r.SKU
	ownerOrgID := r.OwnerOrgID
	storeID := r.StoreID
	input := &service.CreateProductInput{
		Product: domain.CreateProductParams{
			SKU:                     &sku,
			Title:                   r.Title,
			Description:             r.Description,
			StoreID:                 &storeID,
			OwnerOrgID:              &ownerOrgID,
			MainPrice:               r.MainPrice,
			StrikethroughPrice:      r.StrikethroughPrice,
			CostPrice:               r.CostPrice,
			TaxRate:                 r.TaxRate,
			StockLeft:               r.StockLeft,
			MinimumOrderQuantity:    r.MinimumOrderQuantity,
			NetContent:              r.NetContent,
			ContentUnit:             r.ContentUnit,
			ReferencePrice:          r.ReferencePrice,
			ReferenceUnit:           r.ReferenceUnit,
			LogisticsLength:         r.LogisticsLength,
			LogisticsWidth:          r.LogisticsWidth,
			LogisticsHeight:         r.LogisticsHeight,
			LogisticsWeight:         r.LogisticsWeight,
			LogisticsVolume:         r.LogisticsVolume,
			ShelfCode:               r.ShelfCode,
			IsActive:                r.IsActive,
			IsFeatured:              r.IsFeatured,
			IsMiniAppRecommendation: r.IsMiniAppRecommendation,
			ProductType:             domain.ProductType(r.ProductType),
			ParentID:                r.ParentID,
			IsDefaultVariant:        r.IsDefaultVariant,
		},
		CategoryIDs: r.CategoryIDs,
		SubcatIDs:   r.SubcategoryIDs,
	}

	// Set visibility (default to not_visible if not provided)
	if r.Visibility != "" {
		input.Product.Visibility = domain.ProductVisibility(r.Visibility)
	} else {
		input.Product.Visibility = domain.ProductVisibilityNotVisible
	}

	// Set ETW types
	if r.ETWStoreType != nil {
		st := domain.ETWStoreType(*r.ETWStoreType)
		input.Product.ETWStoreType = &st
	}
	if r.ETWMiniAppType != nil {
		mt := domain.ETWMiniAppType(*r.ETWMiniAppType)
		input.Product.ETWMiniAppType = &mt
	}

	// Convert attributes
	for _, attr := range r.Attributes {
		input.Attributes = append(input.Attributes, domain.CreateAttributeParams{
			AttributeName:  attr.AttributeName,
			AttributeValue: attr.AttributeValue,
			DisplayOrder:   attr.DisplayOrder,
		})
	}

	// Convert images
	for _, img := range r.Images {
		input.Images = append(input.Images, domain.CreateImageParams{
			ImageURL:     img.ImageURL,
			DisplayOrder: img.DisplayOrder,
			IsPrimary:    img.IsPrimary,
		})
	}

	return input
}

// UpdateProductRequest represents a request to update a product.
type UpdateProductRequest struct {
	SKU                     *string           `json:"sku"`
	Title                   *string           `json:"title"`
	Description             *string           `json:"description"`
	StoreID                 *int32            `json:"store_id"`
	OwnerOrgID              *string           `json:"owner_org_id"` // UUID as string
	MainPrice               *float64          `json:"main_price"`
	StrikethroughPrice      *float64          `json:"strikethrough_price"`
	CostPrice               *float64          `json:"cost_price"`
	TaxRate                 *float64          `json:"tax_rate"`
	StockLeft               *int32            `json:"stock_left"`
	MinimumOrderQuantity    *int32            `json:"minimum_order_quantity"`
	NetContent              *float64          `json:"net_content"`
	ContentUnit             *string           `json:"content_unit"`
	ReferencePrice          *float64          `json:"reference_price"`
	ReferenceUnit           *string           `json:"reference_unit"`
	LogisticsLength         *float64          `json:"logistics_length"`
	LogisticsWidth          *float64          `json:"logistics_width"`
	LogisticsHeight         *float64          `json:"logistics_height"`
	LogisticsWeight         *float64          `json:"logistics_weight"`
	LogisticsVolume         *float64          `json:"logistics_volume"`
	ShelfCode               *string           `json:"shelf_code"`
	IsActive                *bool             `json:"is_active"`
	IsFeatured              *bool             `json:"is_featured"`
	IsMiniAppRecommendation *bool             `json:"is_mini_app_recommendation"`
	Visibility              *string           `json:"visibility"`
	IsDefaultVariant        *bool             `json:"is_default_variant"`
	ETWStoreType            *string           `json:"etw_store_type"`
	ETWMiniAppType          *string           `json:"etw_mini_app_type"`
	Attributes              *[]AttributeInput `json:"attributes"`
	Images                  *[]ImageInput     `json:"images"`
	CategoryIDs             *[]int32          `json:"category_ids"`
	SubcategoryIDs          *[]int32          `json:"subcategory_ids"`
}

func (r *UpdateProductRequest) toInput(productID int32) *service.UpdateProductInput {
	input := &service.UpdateProductInput{
		ProductID: productID,
		Product: domain.UpdateProductParams{
			SKU:                     r.SKU,
			Title:                   r.Title,
			Description:             r.Description,
			StoreID:                 r.StoreID,
			OwnerOrgID:              r.OwnerOrgID,
			MainPrice:               r.MainPrice,
			StrikethroughPrice:      r.StrikethroughPrice,
			CostPrice:               r.CostPrice,
			TaxRate:                 r.TaxRate,
			StockLeft:               r.StockLeft,
			MinimumOrderQuantity:    r.MinimumOrderQuantity,
			NetContent:              r.NetContent,
			ContentUnit:             r.ContentUnit,
			ReferencePrice:          r.ReferencePrice,
			ReferenceUnit:           r.ReferenceUnit,
			LogisticsLength:         r.LogisticsLength,
			LogisticsWidth:          r.LogisticsWidth,
			LogisticsHeight:         r.LogisticsHeight,
			LogisticsWeight:         r.LogisticsWeight,
			LogisticsVolume:         r.LogisticsVolume,
			ShelfCode:               r.ShelfCode,
			IsActive:                r.IsActive,
			IsFeatured:              r.IsFeatured,
			IsMiniAppRecommendation: r.IsMiniAppRecommendation,
			IsDefaultVariant:        r.IsDefaultVariant,
		},
		CategoryIDs: r.CategoryIDs,
		SubcatIDs:   r.SubcategoryIDs,
	}

	if r.Visibility != nil {
		v := domain.ProductVisibility(*r.Visibility)
		input.Product.Visibility = &v
	}
	if r.ETWStoreType != nil {
		st := domain.ETWStoreType(*r.ETWStoreType)
		input.Product.ETWStoreType = &st
	}
	if r.ETWMiniAppType != nil {
		mt := domain.ETWMiniAppType(*r.ETWMiniAppType)
		input.Product.ETWMiniAppType = &mt
	}

	// Convert attributes if provided
	if r.Attributes != nil {
		attrs := make([]domain.CreateAttributeParams, 0, len(*r.Attributes))
		for _, attr := range *r.Attributes {
			attrs = append(attrs, domain.CreateAttributeParams{
				AttributeName:  attr.AttributeName,
				AttributeValue: attr.AttributeValue,
				DisplayOrder:   attr.DisplayOrder,
			})
		}
		input.Attributes = &attrs
	}

	// Convert images if provided
	if r.Images != nil {
		imgs := make([]domain.CreateImageParams, 0, len(*r.Images))
		for _, img := range *r.Images {
			imgs = append(imgs, domain.CreateImageParams{
				ImageURL:     img.ImageURL,
				DisplayOrder: img.DisplayOrder,
				IsPrimary:    img.IsPrimary,
			})
		}
		input.Images = &imgs
	}

	return input
}

// ProductResponse represents a product in API responses.
type ProductResponse struct {
	ProductID               int32                      `json:"product_id"`
	ProductUUID             string                     `json:"product_uuid"`
	SKU                     *string                    `json:"sku"`
	Title                   *string                    `json:"title"`
	Description             *string                    `json:"description"`
	StoreID                 *int32                     `json:"store_id"`
	OwnerOrgID              *string                    `json:"owner_org_id"`
	MainPrice               *float64                   `json:"main_price"`
	StrikethroughPrice      *float64                   `json:"strikethrough_price"`
	CostPrice               *float64                   `json:"cost_price"`
	TaxRate                 *float64                   `json:"tax_rate"`
	StockLeft               *int32                     `json:"stock_left"`
	MinimumOrderQuantity    *int32                     `json:"minimum_order_quantity"`
	NetContent              *float64                   `json:"net_content"`
	ContentUnit             *string                    `json:"content_unit"`
	ReferencePrice          *float64                   `json:"reference_price"`
	ReferenceUnit           *string                    `json:"reference_unit"`
	LogisticsLength         *float64                   `json:"logistics_length"`
	LogisticsWidth          *float64                   `json:"logistics_width"`
	LogisticsHeight         *float64                   `json:"logistics_height"`
	LogisticsWeight         *float64                   `json:"logistics_weight"`
	LogisticsVolume         *float64                   `json:"logistics_volume"`
	ShelfCode               *string                    `json:"shelf_code"`
	IsActive                bool                       `json:"is_active"`
	IsFeatured              bool                       `json:"is_featured"`
	IsMiniAppRecommendation bool                       `json:"is_mini_app_recommendation"`
	IsArchived              bool                       `json:"is_archived"`
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

// VariantOption represents a variant option value with display order.
type VariantOption struct {
	Value        string `json:"value"`
	DisplayOrder int32  `json:"display_order"`
}

// ProductWithRelationsResponse includes product with all relations.
type ProductWithRelationsResponse struct {
	ProductResponse
	Attributes     []AttributeResponse     `json:"attributes"`
	Specifications []SpecificationResponse `json:"specifications"`
	Images         []ImageResponse         `json:"images"`
	Categories     []CategoryResponse      `json:"categories"`
	Subcategories  []SubcategoryResponse   `json:"subcategories,omitempty"`
	Children       []ProductResponse       `json:"children,omitempty"`
}

// AttributeResponse represents a product attribute (variant-defining options).
type AttributeResponse struct {
	AttributeID    int32  `json:"attribute_id"`
	ProductID      int32  `json:"product_id"`
	AttributeName  string `json:"attribute_name"`
	AttributeValue string `json:"attribute_value"`
	DisplayOrder   int32  `json:"display_order"`
	CreatedAt      string `json:"created_at"`
}

// SpecificationResponse represents a product specification (Amazon-style info).
type SpecificationResponse struct {
	SpecificationID int32  `json:"specification_id"`
	ProductID       int32  `json:"product_id"`
	SpecName        string `json:"spec_name"`
	SpecValue       string `json:"spec_value"`
	DisplayOrder    int32  `json:"display_order"`
	CreatedAt       string `json:"created_at"`
}

// ImageResponse represents a product image.
type ImageResponse struct {
	ImageID      int32   `json:"image_id"`
	ProductID    *int32  `json:"product_id"`
	ImageURL     *string `json:"image_url"`
	DisplayOrder int32   `json:"display_order"`
	IsPrimary    bool    `json:"is_primary"`
	CreatedAt    string  `json:"created_at"`
}

// PaginatedProductsResponse represents a paginated list of products.
type PaginatedProductsResponse struct {
	Items      []ProductResponse `json:"items"`
	TotalCount int64             `json:"total_count"`
	Page       int               `json:"page"`
	PageSize   int               `json:"page_size"`
	TotalPages int               `json:"total_pages"`
}

func toProductResponse(p *domain.Product) ProductResponse {
	resp := ProductResponse{
		ProductID:               p.ProductID,
		ProductUUID:             p.ProductUUID,
		SKU:                     p.SKU,
		Title:                   p.Title,
		Description:             p.Description,
		StoreID:                 p.StoreID,
		OwnerOrgID:              p.OwnerOrgID,
		MainPrice:               p.MainPrice,
		StrikethroughPrice:      p.StrikethroughPrice,
		CostPrice:               p.CostPrice,
		TaxRate:                 p.TaxRate,
		StockLeft:               p.StockLeft,
		MinimumOrderQuantity:    p.MinimumOrderQuantity,
		NetContent:              p.NetContent,
		ContentUnit:             p.ContentUnit,
		ReferencePrice:          p.ReferencePrice,
		ReferenceUnit:           p.ReferenceUnit,
		LogisticsLength:         p.LogisticsLength,
		LogisticsWidth:          p.LogisticsWidth,
		LogisticsHeight:         p.LogisticsHeight,
		LogisticsWeight:         p.LogisticsWeight,
		LogisticsVolume:         p.LogisticsVolume,
		ShelfCode:               p.ShelfCode,
		IsActive:                p.IsActive,
		IsFeatured:              p.IsFeatured,
		IsMiniAppRecommendation: p.IsMiniAppRecommendation,
		IsArchived:              p.IsArchived,
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

	// Convert variant_options_index
	if p.VariantOptionsIndex != nil {
		resp.VariantOptionsIndex = make(map[string][]VariantOption)
		for name, options := range p.VariantOptionsIndex {
			for _, opt := range options {
				resp.VariantOptionsIndex[name] = append(resp.VariantOptionsIndex[name], VariantOption{
					Value:        opt.Value,
					DisplayOrder: opt.DisplayOrder,
				})
			}
		}
	}

	if p.ETWStoreType != nil {
		s := string(*p.ETWStoreType)
		resp.ETWStoreType = &s
	}
	if p.ETWMiniAppType != nil {
		s := string(*p.ETWMiniAppType)
		resp.ETWMiniAppType = &s
	}

	return resp
}

func toProductWithRelationsResponse(p *domain.ProductWithRelations) *ProductWithRelationsResponse {
	resp := &ProductWithRelationsResponse{
		ProductResponse: toProductResponse(&p.Product),
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
		resp.Children = append(resp.Children, toProductResponse(&child))
	}

	return resp
}

func toPaginatedProductsResponse(result *repository.PaginatedResult[domain.Product]) *PaginatedProductsResponse {
	resp := &PaginatedProductsResponse{
		TotalCount: result.TotalCount,
		Page:       result.Page,
		PageSize:   result.PageSize,
		TotalPages: result.TotalPages,
	}

	for _, p := range result.Items {
		resp.Items = append(resp.Items, toProductResponse(&p))
	}

	return resp
}

// --------------------------------
// Category DTOs
// --------------------------------

// CreateCategoryRequest represents a request to create a category.
type CreateCategoryRequest struct {
	Name           string  `json:"name" binding:"required"`
	ImageURL       *string `json:"image_url"`
	DisplayOrder   int32   `json:"display_order"`
	IsActive       bool    `json:"is_active"`
	StoreID        *int32  `json:"store_id"`
	ETWStoreType   *string `json:"etw_store_type"`
	ETWMiniAppType *string `json:"etw_mini_app_type"`
}

func (r *CreateCategoryRequest) toParams() *domain.CreateCategoryParams {
	params := &domain.CreateCategoryParams{
		Name:         r.Name,
		ImageURL:     r.ImageURL,
		DisplayOrder: r.DisplayOrder,
		IsActive:     r.IsActive,
		StoreID:      r.StoreID,
	}
	if r.ETWStoreType != nil {
		st := domain.ETWStoreType(*r.ETWStoreType)
		params.ETWStoreType = &st
	}
	if r.ETWMiniAppType != nil {
		mt := domain.ETWMiniAppType(*r.ETWMiniAppType)
		params.ETWMiniAppType = &mt
	}
	return params
}

// UpdateCategoryRequest represents a request to update a category.
type UpdateCategoryRequest struct {
	Name           *string `json:"name"`
	ImageURL       *string `json:"image_url"`
	DisplayOrder   *int32  `json:"display_order"`
	IsActive       *bool   `json:"is_active"`
	StoreID        *int32  `json:"store_id"`
	ETWStoreType   *string `json:"etw_store_type"`
	ETWMiniAppType *string `json:"etw_mini_app_type"`
}

func (r *UpdateCategoryRequest) toParams() *domain.UpdateCategoryParams {
	params := &domain.UpdateCategoryParams{
		Name:         r.Name,
		ImageURL:     r.ImageURL,
		DisplayOrder: r.DisplayOrder,
		IsActive:     r.IsActive,
		StoreID:      r.StoreID,
	}
	if r.ETWStoreType != nil {
		st := domain.ETWStoreType(*r.ETWStoreType)
		params.ETWStoreType = &st
	}
	if r.ETWMiniAppType != nil {
		mt := domain.ETWMiniAppType(*r.ETWMiniAppType)
		params.ETWMiniAppType = &mt
	}
	return params
}

// CategoryResponse represents a category in API responses.
type CategoryResponse struct {
	CategoryID       int32   `json:"category_id"`
	Name             string  `json:"name"`
	ImageURL         *string `json:"image_url"`
	DisplayOrder     int32   `json:"display_order"`
	IsActive         bool    `json:"is_active"`
	StoreID          *int32  `json:"store_id"`
	ETWStoreType     *string `json:"etw_store_type"`
	ETWMiniAppType   *string `json:"etw_mini_app_type"`
	SubcategoryCount int     `json:"subcategory_count"`
	CreatedAt        string  `json:"created_at"`
	UpdatedAt        string  `json:"updated_at"`
}

// CategoryWithCountsResponse includes counts.
type CategoryWithCountsResponse struct {
	CategoryResponse
	ProductCount     int `json:"product_count"`
	SubcategoryCount int `json:"subcategory_count"`
}

// CategoryWithSubcategoriesResponse includes subcategories.
type CategoryWithSubcategoriesResponse struct {
	CategoryResponse
	Subcategories []SubcategoryResponse `json:"subcategories"`
}

// PaginatedCategoriesResponse represents a paginated list of categories.
type PaginatedCategoriesResponse struct {
	Items      []CategoryResponse `json:"items"`
	TotalCount int64              `json:"total_count"`
	Page       int                `json:"page"`
	PageSize   int                `json:"page_size"`
	TotalPages int                `json:"total_pages"`
}

func toCategoryResponse(c *domain.Category) *CategoryResponse {
	resp := &CategoryResponse{
		CategoryID:       c.CategoryID,
		Name:             c.Name,
		ImageURL:         c.ImageURL,
		DisplayOrder:     c.DisplayOrder,
		IsActive:         c.IsActive,
		StoreID:          c.StoreID,
		SubcategoryCount: c.SubcategoryCount,
		CreatedAt:        c.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:        c.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
	if c.ETWStoreType != nil {
		s := string(*c.ETWStoreType)
		resp.ETWStoreType = &s
	}
	if c.ETWMiniAppType != nil {
		s := string(*c.ETWMiniAppType)
		resp.ETWMiniAppType = &s
	}
	return resp
}

func toCategoryWithCountsResponse(c *domain.CategoryWithCounts) *CategoryWithCountsResponse {
	resp := &CategoryWithCountsResponse{
		CategoryResponse: *toCategoryResponse(&domain.Category{
			CategoryID:     c.CategoryID,
			Name:           c.Name,
			ImageURL:       c.ImageURL,
			DisplayOrder:   c.DisplayOrder,
			IsActive:       c.IsActive,
			StoreID:        c.StoreID,
			ETWStoreType:   c.ETWStoreType,
			ETWMiniAppType: c.ETWMiniAppType,
			CreatedAt:      c.CreatedAt,
			UpdatedAt:      c.UpdatedAt,
		}),
		ProductCount:     c.ProductCount,
		SubcategoryCount: c.SubcategoryCount,
	}
	return resp
}

func toCategoryWithSubcategoriesResponse(c *domain.CategoryWithSubcategories) *CategoryWithSubcategoriesResponse {
	resp := &CategoryWithSubcategoriesResponse{
		CategoryResponse: *toCategoryResponse(&c.Category),
	}
	for _, sub := range c.Subcategories {
		resp.Subcategories = append(resp.Subcategories, *toSubcategoryResponse(&sub))
	}
	return resp
}

func toPaginatedCategoriesResponse(result *repository.PaginatedResult[domain.Category]) *PaginatedCategoriesResponse {
	resp := &PaginatedCategoriesResponse{
		TotalCount: result.TotalCount,
		Page:       result.Page,
		PageSize:   result.PageSize,
		TotalPages: result.TotalPages,
	}
	for _, c := range result.Items {
		resp.Items = append(resp.Items, *toCategoryResponse(&c))
	}
	return resp
}

func toCategoryTreeResponse(categories []domain.CategoryWithSubcategories) []CategoryWithSubcategoriesResponse {
	var resp []CategoryWithSubcategoriesResponse
	for _, c := range categories {
		resp = append(resp, *toCategoryWithSubcategoriesResponse(&c))
	}
	return resp
}

// --------------------------------
// Subcategory DTOs
// --------------------------------

// CreateSubcategoryRequest represents a request to create a subcategory.
type CreateSubcategoryRequest struct {
	Name         string  `json:"name" binding:"required"`
	ImageURL     *string `json:"image_url"`
	DisplayOrder int32   `json:"display_order"`
	IsActive     bool    `json:"is_active"`
}

func (r *CreateSubcategoryRequest) toParams(categoryID int32) *domain.CreateSubcategoryParams {
	return &domain.CreateSubcategoryParams{
		CategoryID:   categoryID,
		Name:         r.Name,
		ImageURL:     r.ImageURL,
		DisplayOrder: r.DisplayOrder,
		IsActive:     r.IsActive,
	}
}

// UpdateSubcategoryRequest represents a request to update a subcategory.
type UpdateSubcategoryRequest struct {
	Name         *string `json:"name"`
	ImageURL     *string `json:"image_url"`
	DisplayOrder *int32  `json:"display_order"`
	IsActive     *bool   `json:"is_active"`
}

func (r *UpdateSubcategoryRequest) toParams() *domain.UpdateSubcategoryParams {
	return &domain.UpdateSubcategoryParams{
		Name:         r.Name,
		ImageURL:     r.ImageURL,
		DisplayOrder: r.DisplayOrder,
		IsActive:     r.IsActive,
	}
}

// MoveSubcategoryRequest represents a request to move a subcategory.
type MoveSubcategoryRequest struct {
	TargetCategoryID int32 `json:"target_category_id" binding:"required"`
}

// ReorderRequest represents a request to reorder items.
type ReorderRequest struct {
	OrderedIDs []int32 `json:"ordered_ids" binding:"required"`
}

// SubcategoryResponse represents a subcategory in API responses.
type SubcategoryResponse struct {
	SubcategoryID int32   `json:"subcategory_id"`
	CategoryID    int32   `json:"category_id"`
	Name          string  `json:"name"`
	ImageURL      *string `json:"image_url"`
	DisplayOrder  int32   `json:"display_order"`
	IsActive      bool    `json:"is_active"`
	CreatedAt     string  `json:"created_at"`
	UpdatedAt     string  `json:"updated_at"`
}

// SubcategoryWithCountsResponse includes product count.
type SubcategoryWithCountsResponse struct {
	SubcategoryResponse
	ProductCount int `json:"product_count"`
}

func toSubcategoryResponse(s *domain.Subcategory) *SubcategoryResponse {
	return &SubcategoryResponse{
		SubcategoryID: s.SubcategoryID,
		CategoryID:    s.CategoryID,
		Name:          s.Name,
		ImageURL:      s.ImageURL,
		DisplayOrder:  s.DisplayOrder,
		IsActive:      s.IsActive,
		CreatedAt:     s.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:     s.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}

func toSubcategoryWithCountsResponse(s *domain.SubcategoryWithCounts) *SubcategoryWithCountsResponse {
	return &SubcategoryWithCountsResponse{
		SubcategoryResponse: *toSubcategoryResponse(&domain.Subcategory{
			SubcategoryID: s.SubcategoryID,
			CategoryID:    s.CategoryID,
			Name:          s.Name,
			ImageURL:      s.ImageURL,
			DisplayOrder:  s.DisplayOrder,
			IsActive:      s.IsActive,
			CreatedAt:     s.CreatedAt,
			UpdatedAt:     s.UpdatedAt,
		}),
		ProductCount: s.ProductCount,
	}
}

func toSubcategoriesResponse(subcategories []domain.Subcategory) []SubcategoryResponse {
	var resp []SubcategoryResponse
	for _, s := range subcategories {
		resp = append(resp, *toSubcategoryResponse(&s))
	}
	return resp
}

// --------------------------------
// Store DTOs
// --------------------------------

// CreateStoreRequest represents a request to create a store.
type CreateStoreRequest struct {
	Name           string   `json:"name" binding:"required"`
	City           *string  `json:"city"`
	Address        *string  `json:"address"`
	Latitude       *float64 `json:"latitude"`
	Longitude      *float64 `json:"longitude"`
	ImageURL       *string  `json:"image_url"`
	RegionID       *int32   `json:"region_id"`
	IsActive       bool     `json:"is_active"`
	ETWStoreType   *string  `json:"etw_store_type"`
	ETWMiniAppType *string  `json:"etw_mini_app_type"`
}

func (r *CreateStoreRequest) toParams() *domain.CreateStoreParams {
	params := &domain.CreateStoreParams{
		Name:      r.Name,
		City:      r.City,
		Address:   r.Address,
		Latitude:  r.Latitude,
		Longitude: r.Longitude,
		ImageURL:  r.ImageURL,
		RegionID:  r.RegionID,
		IsActive:  r.IsActive,
	}
	if r.ETWStoreType != nil {
		st := domain.ETWStoreType(*r.ETWStoreType)
		params.ETWStoreType = &st
	}
	if r.ETWMiniAppType != nil {
		mt := domain.ETWMiniAppType(*r.ETWMiniAppType)
		params.ETWMiniAppType = &mt
	}
	return params
}

// UpdateStoreRequest represents a request to update a store.
type UpdateStoreRequest struct {
	Name           *string  `json:"name"`
	City           *string  `json:"city"`
	Address        *string  `json:"address"`
	Latitude       *float64 `json:"latitude"`
	Longitude      *float64 `json:"longitude"`
	ImageURL       *string  `json:"image_url"`
	RegionID       *int32   `json:"region_id"`
	IsActive       *bool    `json:"is_active"`
	ETWStoreType   *string  `json:"etw_store_type"`
	ETWMiniAppType *string  `json:"etw_mini_app_type"`
}

func (r *UpdateStoreRequest) toParams() *domain.UpdateStoreParams {
	params := &domain.UpdateStoreParams{
		Name:      r.Name,
		City:      r.City,
		Address:   r.Address,
		Latitude:  r.Latitude,
		Longitude: r.Longitude,
		ImageURL:  r.ImageURL,
		RegionID:  r.RegionID,
		IsActive:  r.IsActive,
	}
	if r.ETWStoreType != nil {
		st := domain.ETWStoreType(*r.ETWStoreType)
		params.ETWStoreType = &st
	}
	if r.ETWMiniAppType != nil {
		mt := domain.ETWMiniAppType(*r.ETWMiniAppType)
		params.ETWMiniAppType = &mt
	}
	return params
}

// StoreResponse represents a store in API responses.
type StoreResponse struct {
	StoreID        int32    `json:"store_id"`
	Name           string   `json:"name"`
	City           *string  `json:"city"`
	Address        *string  `json:"address"`
	Latitude       *float64 `json:"latitude"`
	Longitude      *float64 `json:"longitude"`
	ImageURL       *string  `json:"image_url"`
	RegionID       *int32   `json:"region_id"`
	IsActive       bool     `json:"is_active"`
	ETWStoreType   *string  `json:"etw_store_type"`
	ETWMiniAppType *string  `json:"etw_mini_app_type"`
	CreatedAt      string   `json:"created_at"`
	UpdatedAt      string   `json:"updated_at"`
}

// StoreWithCountsResponse includes product count.
type StoreWithCountsResponse struct {
	StoreResponse
	ProductCount int `json:"product_count"`
}

// PaginatedStoresResponse represents a paginated list of stores.
type PaginatedStoresResponse struct {
	Items      []StoreResponse `json:"items"`
	TotalCount int64           `json:"total_count"`
	Page       int             `json:"page"`
	PageSize   int             `json:"page_size"`
	TotalPages int             `json:"total_pages"`
}

func toStoreResponse(s *domain.Store) *StoreResponse {
	resp := &StoreResponse{
		StoreID:   s.StoreID,
		Name:      s.Name,
		City:      s.City,
		Address:   s.Address,
		Latitude:  s.Latitude,
		Longitude: s.Longitude,
		ImageURL:  s.ImageURL,
		RegionID:  s.RegionID,
		IsActive:  s.IsActive,
		CreatedAt: s.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt: s.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
	if s.ETWStoreType != nil {
		st := string(*s.ETWStoreType)
		resp.ETWStoreType = &st
	}
	if s.ETWMiniAppType != nil {
		mt := string(*s.ETWMiniAppType)
		resp.ETWMiniAppType = &mt
	}
	return resp
}

func toPaginatedStoresResponse(result *repository.PaginatedResult[domain.Store]) *PaginatedStoresResponse {
	resp := &PaginatedStoresResponse{
		TotalCount: result.TotalCount,
		Page:       result.Page,
		PageSize:   result.PageSize,
		TotalPages: result.TotalPages,
	}
	for _, s := range result.Items {
		resp.Items = append(resp.Items, *toStoreResponse(&s))
	}
	return resp
}

// --------------------------------
// Region DTOs
// --------------------------------

// CreateRegionRequest represents a request to create a region.
type CreateRegionRequest struct {
	StoreID     *int32  `json:"store_id"`
	Name        string  `json:"name" binding:"required"`
	Description *string `json:"description"`
}

func (r *CreateRegionRequest) toParams() *domain.CreateRegionParams {
	return &domain.CreateRegionParams{
		StoreID:     r.StoreID,
		Name:        r.Name,
		Description: r.Description,
	}
}

// UpdateRegionRequest represents a request to update a region.
type UpdateRegionRequest struct {
	StoreID     *int32  `json:"store_id"`
	Name        *string `json:"name"`
	Description *string `json:"description"`
}

func (r *UpdateRegionRequest) toParams() *domain.UpdateRegionParams {
	return &domain.UpdateRegionParams{
		StoreID:     r.StoreID,
		Name:        r.Name,
		Description: r.Description,
	}
}

// RegionResponse represents a region in API responses.
type RegionResponse struct {
	RegionID    int32   `json:"region_id"`
	StoreID     *int32  `json:"store_id"`
	Name        string  `json:"name"`
	Description *string `json:"description"`
	CreatedAt   string  `json:"created_at"`
	UpdatedAt   string  `json:"updated_at"`
}

func toRegionResponse(r *domain.Region) *RegionResponse {
	return &RegionResponse{
		RegionID:    r.RegionID,
		StoreID:     r.StoreID,
		Name:        r.Name,
		Description: r.Description,
		CreatedAt:   r.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:   r.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}

func toRegionsResponse(regions []domain.Region) []RegionResponse {
	var resp []RegionResponse
	for _, r := range regions {
		resp = append(resp, *toRegionResponse(&r))
	}
	return resp
}
