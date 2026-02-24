// Package domain contains the core business entities for the catalog service.
package domain

import (
	"time"
)

// Product represents a product entity in the catalog system.
// It supports three product types:
// - Standard: A standalone product with no variants
// - Parent: A product that has child variants (e.g., "T-Shirt" with Size/Color variants)
// - Child: A variant belonging to a parent product (e.g., "T-Shirt - Red - Large")
//
// Parent-specific fields (PriceMin, PriceMax, StockTotal, VariantOptionsIndex) are
// automatically computed by SyncParentAggregates and should be NULL for standard/child products.
type Product struct {
	// Core identifiers
	ProductID   int32   // Primary key (serial)
	ProductUUID string  // UUID for external reference
	SKU         *string // Stock Keeping Unit (nullable, unique among active non-parent products)

	// Basic info
	Title       *string
	Description *string

	// Store & Organization
	StoreID    *int32  // FK to admin_stores
	OwnerOrgID *string // FK to admin_organizations (UUID)

	// Pricing (nullable for parent products)
	MainPrice          *float64 // Current selling price
	StrikethroughPrice *float64 // Original/compare price
	CostPrice          *float64 // Cost price for profit calculation
	TaxRate            *float64 // Tax rate percentage (e.g., 22 for 22% VAT)

	// Inventory (nullable for parent products)
	StockLeft            *int32 // Current stock level
	MinimumOrderQuantity *int32 // Minimum pack quantity (default: 1)

	// Content & Unit Pricing (EU Price Indication Directive compliance)
	NetContent     *float64 // Net content value (weight/volume/length/count)
	ContentUnit    *string  // Unit for net content: g, KG, mL, L, cm, M, PC, PCS, Unit
	ReferencePrice *float64 // Price per reference unit (e.g., €2.00/kg)
	ReferenceUnit  *string  // Reference unit: KG, L, M, PC, PCS, Unit

	// Logistics (shipping dimensions)
	LogisticsLength *float64 // Package length in cm
	LogisticsWidth  *float64 // Package width in cm
	LogisticsHeight *float64 // Package height in cm
	LogisticsWeight *float64 // Package weight in grams
	LogisticsVolume *float64 // Calculated volume in cm³

	// Shelf management
	ShelfCode *string // Store-specific shelf/bin code

	// Flags
	IsActive                bool // Whether the product is active
	IsFeatured              bool // Whether the product is featured
	IsMiniAppRecommendation bool // Whether shown in mini-app recommendations
	IsArchived              bool // Soft delete flag

	// Product Type & Variant System
	ProductType      ProductType       // standard | parent | child
	ParentID         *int32            // FK to parent product (required for child, NULL otherwise)
	Visibility       ProductVisibility // visible | not_visible (children must be not_visible)
	IsDefaultVariant bool              // Whether this child is the default variant

	// Parent Aggregates (NULL for standard/child products, computed by SyncParentAggregates)
	PriceMin            *float64            // Minimum price among active children
	PriceMax            *float64            // Maximum price among active children
	StockTotal          *int32              // Sum of stock from all active children
	VariantOptionsIndex VariantOptionsIndex // JSON index of variant options for quick lookup

	// ETW Type classifications
	ETWStoreType   *ETWStoreType   // Store type classification
	ETWMiniAppType *ETWMiniAppType // Mini-app type classification

	// Computed/Joined field for list views (not stored in DB)
	PrimaryImageURL *string // URL of the primary product image (populated from joins)

	// Timestamps
	CreatedAt time.Time
	UpdatedAt time.Time
}

// IsParent returns true if this is a parent product with variants.
func (p *Product) IsParent() bool {
	return p.ProductType == ProductTypeParent
}

// IsChild returns true if this is a child variant product.
func (p *Product) IsChild() bool {
	return p.ProductType == ProductTypeChild
}

// IsStandard returns true if this is a standalone product without variants.
func (p *Product) IsStandard() bool {
	return p.ProductType == ProductTypeStandard
}

// CanBeVisible returns true if this product can have visible visibility.
// Only standard and parent products can be visible; children are always not_visible.
func (p *Product) CanBeVisible() bool {
	return p.ProductType != ProductTypeChild
}

// HasStock returns true if the product has stock available.
// For parent products, checks StockTotal; for others, checks StockLeft.
func (p *Product) HasStock() bool {
	if p.IsParent() {
		return p.StockTotal != nil && *p.StockTotal > 0
	}
	return p.StockLeft != nil && *p.StockLeft > 0
}

// GetEffectivePrice returns the display price for the product.
// For parent products, returns the minimum price; for others, returns MainPrice.
func (p *Product) GetEffectivePrice() *float64 {
	if p.IsParent() {
		return p.PriceMin
	}
	return p.MainPrice
}

// GetPriceRange returns the price range for display purposes.
// For parent products, returns (min, max); for others, returns (price, price).
func (p *Product) GetPriceRange() (*float64, *float64) {
	if p.IsParent() {
		return p.PriceMin, p.PriceMax
	}
	return p.MainPrice, p.MainPrice
}

// ProductWithRelations extends Product with related entities loaded.
type ProductWithRelations struct {
	Product
	Images         []ProductImage         // Product images
	Attributes     []ProductAttribute     // Product attributes (for child variants)
	Specifications []ProductSpecification // Product specifications (Amazon-style info)
	Categories     []Category             // Associated categories
	Children       []Product              // Child variants (for parent products)
}

// CreateProductParams contains the parameters for creating a new product.
type CreateProductParams struct {
	SKU                     *string
	Title                   string
	Description             *string
	StoreID                 *int32
	OwnerOrgID              *string
	MainPrice               *float64
	StrikethroughPrice      *float64
	CostPrice               *float64
	TaxRate                 *float64
	StockLeft               *int32
	MinimumOrderQuantity    *int32
	NetContent              *float64
	ContentUnit             *string
	ReferencePrice          *float64
	ReferenceUnit           *string
	LogisticsLength         *float64
	LogisticsWidth          *float64
	LogisticsHeight         *float64
	LogisticsWeight         *float64
	LogisticsVolume         *float64
	ShelfCode               *string
	IsActive                bool
	IsFeatured              bool
	IsMiniAppRecommendation bool
	ProductType             ProductType
	ParentID                *int32
	Visibility              ProductVisibility
	IsDefaultVariant        bool
	ETWStoreType            *ETWStoreType
	ETWMiniAppType          *ETWMiniAppType
	CategoryIDs             []int32 // Categories to associate
	SubcategoryIDs          []int32 // Subcategories to associate
	CollectionIDs           []int32 // Collections to associate
}

// UpdateProductParams contains the parameters for updating an existing product.
type UpdateProductParams struct {
	SKU                     *string
	Title                   *string
	Description             *string
	StoreID                 *int32
	OwnerOrgID              *string
	MainPrice               *float64
	StrikethroughPrice      *float64
	CostPrice               *float64
	TaxRate                 *float64
	StockLeft               *int32
	MinimumOrderQuantity    *int32
	NetContent              *float64
	ContentUnit             *string
	ReferencePrice          *float64
	ReferenceUnit           *string
	LogisticsLength         *float64
	LogisticsWidth          *float64
	LogisticsHeight         *float64
	LogisticsWeight         *float64
	LogisticsVolume         *float64
	ShelfCode               *string
	IsActive                *bool
	IsFeatured              *bool
	IsMiniAppRecommendation *bool
	IsArchived              *bool
	Visibility              *ProductVisibility
	IsDefaultVariant        *bool
	ETWStoreType            *ETWStoreType
	ETWMiniAppType          *ETWMiniAppType
}

// UpdateParentAggregatesParams contains the computed aggregates for a parent product.
type UpdateParentAggregatesParams struct {
	PriceMin            *float64
	PriceMax            *float64
	StockTotal          int32
	VariantOptionsIndex VariantOptionsIndex
}

// ProductFilter contains filter options for listing products.
type ProductFilter struct {
	StoreID        *int32
	OwnerOrgID     *string
	CategoryID     *int32
	SubcategoryID  *int32
	CollectionID   *int32
	ProductType    *ProductType
	Visibility     *ProductVisibility
	IsActive       *bool
	IsFeatured     *bool
	IsArchived     *bool
	ParentID       *int32
	ETWStoreType   *ETWStoreType
	ETWMiniAppType *ETWMiniAppType
	Search         *string // Search in title, description, SKU
	MinPrice       *float64
	MaxPrice       *float64
}

// ProductSort defines sorting options for product listings.
type ProductSort struct {
	Field     string // created_at, updated_at, title, main_price, stock_left
	Direction string // asc, desc
}

// DefaultProductSort returns the default sorting configuration.
func DefaultProductSort() ProductSort {
	return ProductSort{
		Field:     "created_at",
		Direction: "desc",
	}
}
