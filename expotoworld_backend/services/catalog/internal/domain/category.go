// Package domain contains the core business entities for the catalog service.
package domain

import (
	"time"
)

// Category represents a product category.
type Category struct {
	CategoryID       int32
	Name             string
	ImageURL         *string
	DisplayOrder     int32
	IsActive         bool
	StoreID          *int32          // FK to admin_stores (optional)
	ETWStoreType     *ETWStoreType   // Store type classification
	ETWMiniAppType   *ETWMiniAppType // Mini-app type classification
	SubcategoryCount int             // Number of subcategories (computed)
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

// CategoryWithCounts extends Category with computed counts.
type CategoryWithCounts struct {
	CategoryID       int32
	Name             string
	ImageURL         *string
	DisplayOrder     int32
	IsActive         bool
	StoreID          *int32
	ETWStoreType     *ETWStoreType
	ETWMiniAppType   *ETWMiniAppType
	CreatedAt        time.Time
	UpdatedAt        time.Time
	ProductCount     int // Number of products in this category
	SubcategoryCount int // Number of subcategories
}

// CategoryWithSubcategories extends Category with its subcategories.
type CategoryWithSubcategories struct {
	Category
	Subcategories []Subcategory
}

// CreateCategoryParams contains the parameters for creating a new category.
type CreateCategoryParams struct {
	Name           string
	ImageURL       *string
	DisplayOrder   int32
	IsActive       bool
	StoreID        *int32
	ETWStoreType   *ETWStoreType
	ETWMiniAppType *ETWMiniAppType
}

// UpdateCategoryParams contains the parameters for updating an existing category.
type UpdateCategoryParams struct {
	Name           *string
	ImageURL       *string
	DisplayOrder   *int32
	IsActive       *bool
	StoreID        *int32
	ETWStoreType   *ETWStoreType
	ETWMiniAppType *ETWMiniAppType
}

// CategoryFilter contains filter options for listing categories.
type CategoryFilter struct {
	StoreID        *int32
	IsActive       *bool
	ETWStoreType   *ETWStoreType
	ETWMiniAppType *ETWMiniAppType
	Search         *string
}

// Subcategory represents a product subcategory belonging to a parent category.
type Subcategory struct {
	SubcategoryID int32
	CategoryID    int32 // FK to admin_product_categories
	Name          string
	ImageURL      *string
	DisplayOrder  int32
	IsActive      bool
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

// SubcategoryWithCounts extends Subcategory with computed counts.
type SubcategoryWithCounts struct {
	SubcategoryID int32
	CategoryID    int32
	Name          string
	ImageURL      *string
	DisplayOrder  int32
	IsActive      bool
	CreatedAt     time.Time
	UpdatedAt     time.Time
	ProductCount  int // Number of products in this subcategory
}

// CreateSubcategoryParams contains the parameters for creating a new subcategory.
type CreateSubcategoryParams struct {
	CategoryID   int32
	Name         string
	ImageURL     *string
	DisplayOrder int32
	IsActive     bool
}

// UpdateSubcategoryParams contains the parameters for updating an existing subcategory.
type UpdateSubcategoryParams struct {
	CategoryID   *int32
	Name         *string
	ImageURL     *string
	DisplayOrder *int32
	IsActive     *bool
}

// SubcategoryFilter contains filter options for listing subcategories.
type SubcategoryFilter struct {
	ParentCategoryID *int32
	IsActive         *bool
	Search           *string
}

// CategoryTree represents the full category hierarchy with nested subcategories.
type CategoryTree struct {
	Categories []CategoryWithSubcategories
}

// CategoryMapping represents the association between a product and a category.
type CategoryMapping struct {
	ProductID  int32
	CategoryID int32
}

// SubcategoryMapping represents the association between a product and a subcategory.
type SubcategoryMapping struct {
	ProductID     int32
	SubcategoryID int32
}
