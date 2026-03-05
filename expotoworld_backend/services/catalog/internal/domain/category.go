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
	ProductCount     int             // Number of products mapped to this category (computed)
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
	ProductCount  int // Number of products mapped to this subcategory (computed)
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

// Collection represents a product collection belonging to a parent subcategory.
type Collection struct {
	CollectionID  int32
	SubcategoryID int32 // FK to admin_product_subcategory
	Name          string
	ImageURL      *string
	DisplayOrder  int32
	IsActive      bool
	ProductCount  int // Number of products mapped to this collection (computed)
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

// CollectionWithCounts extends Collection with computed counts.
type CollectionWithCounts struct {
	CollectionID  int32
	SubcategoryID int32
	Name          string
	ImageURL      *string
	DisplayOrder  int32
	IsActive      bool
	CreatedAt     time.Time
	UpdatedAt     time.Time
	ProductCount  int // Number of products in this collection
}

// CreateCollectionParams contains the parameters for creating a new collection.
type CreateCollectionParams struct {
	SubcategoryID int32
	Name          string
	ImageURL      *string
	DisplayOrder  int32
	IsActive      bool
}

// UpdateCollectionParams contains the parameters for updating an existing collection.
type UpdateCollectionParams struct {
	SubcategoryID *int32
	Name          *string
	ImageURL      *string
	DisplayOrder  *int32
	IsActive      *bool
}

// CollectionFilter contains filter options for listing collections.
type CollectionFilter struct {
	ParentSubcategoryID *int32
	IsActive            *bool
	Search              *string
}

// Subcollection represents a product subcollection belonging to a parent collection.
type Subcollection struct {
	SubcollectionID int32
	CollectionID    int32 // FK to admin_product_collection
	Name            string
	ImageURL        *string
	DisplayOrder    int32
	IsActive        bool
	ProductCount    int // Number of products mapped to this subcollection (computed)
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

// SubcollectionWithCounts extends Subcollection with computed counts.
type SubcollectionWithCounts struct {
	SubcollectionID int32
	CollectionID    int32
	Name            string
	ImageURL        *string
	DisplayOrder    int32
	IsActive        bool
	CreatedAt       time.Time
	UpdatedAt       time.Time
	ProductCount    int
}

// CreateSubcollectionParams contains the parameters for creating a new subcollection.
type CreateSubcollectionParams struct {
	CollectionID int32
	Name         string
	ImageURL     *string
	DisplayOrder int32
	IsActive     bool
}

// UpdateSubcollectionParams contains the parameters for updating an existing subcollection.
type UpdateSubcollectionParams struct {
	CollectionID *int32
	Name         *string
	ImageURL     *string
	DisplayOrder *int32
	IsActive     *bool
}

// SubcollectionFilter contains filter options for listing subcollections.
type SubcollectionFilter struct {
	ParentCollectionID *int32
	IsActive           *bool
	Search             *string
}

// CollectionWithSubcollections extends Collection with its subcollections.
type CollectionWithSubcollections struct {
	Collection
	Subcollections []Subcollection
}

// SubcategoryWithCollections extends Subcategory with its collections.
type SubcategoryWithCollections struct {
	Subcategory
	Collections []CollectionWithSubcollections
}

// CategoryWithFullHierarchy extends Category with the full 4-tier hierarchy.
type CategoryWithFullHierarchy struct {
	Category
	Subcategories []SubcategoryWithCollections
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

// CollectionMapping represents the association between a product and a collection.
type CollectionMapping struct {
	ProductID    int32
	CollectionID int32
}

// SubcollectionMapping represents the association between a product and a subcollection.
type SubcollectionMapping struct {
	ProductID       int32
	SubcollectionID int32
}
