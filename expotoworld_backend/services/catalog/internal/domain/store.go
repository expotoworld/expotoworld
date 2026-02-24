// Package domain contains the core business entities for the catalog service.
package domain

import (
	"time"
)

// Store represents a store entity.
type Store struct {
	StoreID        int32
	Name           string
	City           *string
	Address        *string
	Latitude       *float64
	Longitude      *float64
	ImageURL       *string
	RegionID       *int32          // FK to admin_regions
	ETWStoreType   *ETWStoreType   // Store type classification
	ETWMiniAppType *ETWMiniAppType // Mini-app type classification
	IsActive       bool
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

// StoreWithCounts extends Store with computed counts.
type StoreWithCounts struct {
	Store
	ProductCount  int // Number of products in this store
	CategoryCount int // Number of categories in this store
}

// CreateStoreParams contains the parameters for creating a new store.
type CreateStoreParams struct {
	Name           string
	City           *string
	Address        *string
	Latitude       *float64
	Longitude      *float64
	ImageURL       *string
	RegionID       *int32
	ETWStoreType   *ETWStoreType
	ETWMiniAppType *ETWMiniAppType
	IsActive       bool
}

// UpdateStoreParams contains the parameters for updating an existing store.
type UpdateStoreParams struct {
	Name           *string
	City           *string
	Address        *string
	Latitude       *float64
	Longitude      *float64
	ImageURL       *string
	RegionID       *int32
	ETWStoreType   *ETWStoreType
	ETWMiniAppType *ETWMiniAppType
	IsActive       *bool
}

// StoreFilter contains filter options for listing stores.
type StoreFilter struct {
	RegionID       *int32
	IsActive       *bool
	ETWStoreType   *ETWStoreType
	ETWMiniAppType *ETWMiniAppType
	Search         *string
}

// Region represents a geographical region.
type Region struct {
	RegionID    int32
	StoreID     *int32
	Name        string
	Description *string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// CreateRegionParams contains the parameters for creating a new region.
type CreateRegionParams struct {
	StoreID     *int32
	Name        string
	Description *string
}

// UpdateRegionParams contains the parameters for updating an existing region.
type UpdateRegionParams struct {
	StoreID     *int32
	Name        *string
	Description *string
}

// RegionFilter contains filter options for listing regions.
type RegionFilter struct {
	StoreID *int32
	Search  *string
}
