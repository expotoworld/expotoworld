package models

import (
	"database/sql/driver"
	"fmt"
	"strings"
	"time"
)

// StoreType represents the type of store (ETW naming - primary)
type StoreType string

const (
	// ETW Store Types (primary)
	StoreTypeETWMega   StoreType = "ETWMega"
	StoreTypeETWMarket StoreType = "ETWMarket"
	StoreTypeETWtoGO   StoreType = "ETWtoGO"
	StoreTypeETWXpress StoreType = "ETWXpress"
)

// MiniAppType represents the type of mini-app (ETW naming)
type MiniAppType string

const (
	// ETW Mini-App Types
	MiniAppTypeETWtoB MiniAppType = "ETWtoB" // B2B / Retail Store
	MiniAppTypeETWtoC MiniAppType = "ETWtoC" // B2C / Exhibition Sales
	MiniAppTypeETWtoU MiniAppType = "ETWtoU" // Unmanned Store
	MiniAppTypeETWtoG MiniAppType = "ETWtoG" // Group Buying
)

// MiniAppTypeArray represents an array of MiniAppType for PostgreSQL array support
type MiniAppTypeArray []MiniAppType

// Value implements the driver.Valuer interface for database storage
func (a MiniAppTypeArray) Value() (driver.Value, error) {
	if len(a) == 0 {
		return "{}", nil
	}

	strs := make([]string, len(a))
	for i, v := range a {
		strs[i] = string(v)
	}
	return "{" + strings.Join(strs, ",") + "}", nil
}

// Scan implements the sql.Scanner interface for database retrieval
func (a *MiniAppTypeArray) Scan(value interface{}) error {
	if value == nil {
		*a = MiniAppTypeArray{}
		return nil
	}

	switch v := value.(type) {
	case string:
		// Remove braces and split by comma
		v = strings.Trim(v, "{}")
		if v == "" {
			*a = MiniAppTypeArray{}
			return nil
		}

		parts := strings.Split(v, ",")
		result := make(MiniAppTypeArray, len(parts))
		for i, part := range parts {
			result[i] = MiniAppType(strings.TrimSpace(part))
		}
		*a = result
		return nil
	default:
		return fmt.Errorf("cannot scan %T into MiniAppTypeArray", value)
	}
}

// ETWMiniAppType represents the ETW mini-app type (ETWtoB, ETWtoC, ETWtoU, ETWtoG)
type ETWMiniAppType string

const (
	ETWMiniAppTypeETWtoB ETWMiniAppType = "ETWtoB"
	ETWMiniAppTypeETWtoC ETWMiniAppType = "ETWtoC"
	ETWMiniAppTypeETWtoU ETWMiniAppType = "ETWtoU"
	ETWMiniAppTypeETWtoG ETWMiniAppType = "ETWtoG"
)

// ETWStoreType represents the ETW store type (ETWMega, ETWMarket, ETWtoGO, ETWXpress)
type ETWStoreType string

const (
	ETWStoreTypeMega   ETWStoreType = "ETWMega"
	ETWStoreTypeMarket ETWStoreType = "ETWMarket"
	ETWStoreTypeToGO   ETWStoreType = "ETWtoGO"
	ETWStoreTypeXpress ETWStoreType = "ETWXpress"
)

// ETWStoreTypeArray represents an array of ETWStoreType for PostgreSQL array support
type ETWStoreTypeArray []ETWStoreType

// Value implements the driver.Valuer interface for database storage
func (a ETWStoreTypeArray) Value() (driver.Value, error) {
	if len(a) == 0 {
		return "{}", nil
	}

	strs := make([]string, len(a))
	for i, v := range a {
		strs[i] = string(v)
	}
	return "{" + strings.Join(strs, ",") + "}", nil
}

// Scan implements the sql.Scanner interface for database retrieval
func (a *ETWStoreTypeArray) Scan(value interface{}) error {
	if value == nil {
		*a = ETWStoreTypeArray{}
		return nil
	}

	switch v := value.(type) {
	case string:
		// Remove braces and split by comma
		v = strings.Trim(v, "{}")
		if v == "" {
			*a = ETWStoreTypeArray{}
			return nil
		}

		parts := strings.Split(v, ",")
		result := make(ETWStoreTypeArray, len(parts))
		for i, part := range parts {
			result[i] = ETWStoreType(strings.TrimSpace(part))
		}
		*a = result
		return nil
	default:
		return fmt.Errorf("cannot scan %T into ETWStoreTypeArray", value)
	}
}

// ETWMiniAppTypeArray represents an array of ETWMiniAppType for PostgreSQL array support
type ETWMiniAppTypeArray []ETWMiniAppType

// Value implements the driver.Valuer interface for database storage
func (a ETWMiniAppTypeArray) Value() (driver.Value, error) {
	if len(a) == 0 {
		return "{}", nil
	}

	strs := make([]string, len(a))
	for i, v := range a {
		strs[i] = string(v)
	}
	return "{" + strings.Join(strs, ",") + "}", nil
}

// Scan implements the sql.Scanner interface for database retrieval
func (a *ETWMiniAppTypeArray) Scan(value interface{}) error {
	if value == nil {
		*a = ETWMiniAppTypeArray{}
		return nil
	}

	switch v := value.(type) {
	case string:
		// Remove braces and split by comma
		v = strings.Trim(v, "{}")
		if v == "" {
			*a = ETWMiniAppTypeArray{}
			return nil
		}

		parts := strings.Split(v, ",")
		result := make(ETWMiniAppTypeArray, len(parts))
		for i, part := range parts {
			result[i] = ETWMiniAppType(strings.TrimSpace(part))
		}
		*a = result
		return nil
	default:
		return fmt.Errorf("cannot scan %T into ETWMiniAppTypeArray", value)
	}
}

// Product represents a product in the catalog
type Product struct {
	ID                      int             `json:"id" db:"product_id"`
	UUID                    string          `json:"uuid" db:"product_uuid"`
	SKU                     string          `json:"sku" db:"sku"`
	Title                   string          `json:"title" db:"title"`
	DescriptionShort        string          `json:"description_short" db:"description_short"`
	DescriptionLong         string          `json:"description_long" db:"description_long"`
	StoreType               StoreType       `json:"store_type" db:"store_type"`
	MiniAppType             MiniAppType     `json:"mini_app_type" db:"mini_app_type"`
	ETWStoreType            *ETWStoreType   `json:"etw_store_type,omitempty" db:"etw_store_type"`
	ETWMiniAppType          *ETWMiniAppType `json:"etw_mini_app_type,omitempty" db:"etw_mini_app_type"`
	StoreID                 *int            `json:"store_id" db:"store_id"`
	ShelfCode               *string         `json:"shelf_code,omitempty" db:"shelf_code"`
	MainPrice               float64         `json:"main_price" db:"main_price"`
	StrikethroughPrice      *float64        `json:"strikethrough_price" db:"strikethrough_price"`
	CostPrice               *float64        `json:"cost_price,omitempty" db:"cost_price"` // Admin only - excluded from public API
	Weight                  float64         `json:"weight" db:"weight"`
	StockLeft               int             `json:"stock_left" db:"stock_left"`
	MinimumOrderQuantity    int             `json:"minimum_order_quantity" db:"minimum_order_quantity"`
	IsActive                bool            `json:"is_active" db:"is_active"`
	IsFeatured              bool            `json:"is_featured" db:"is_featured"`
	IsMiniAppRecommendation bool            `json:"is_mini_app_recommendation" db:"is_mini_app_recommendation"`
	ImageUrls               []string        `json:"image_urls"`
	CategoryIds             []string        `json:"category_ids"`
	SubcategoryIds          []string        `json:"subcategory_ids"`
	StockQuantity           *int            `json:"stock_quantity"` // Legacy field for backward compatibility
	CreatedAt               time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt               time.Time       `json:"updated_at" db:"updated_at"`
}

// PublicProduct represents a product for public API (excludes cost_price)
type PublicProduct struct {
	ID                      int             `json:"id"`
	UUID                    string          `json:"uuid"`
	SKU                     string          `json:"sku"`
	Title                   string          `json:"title"`
	DescriptionShort        string          `json:"description_short"`
	DescriptionLong         string          `json:"description_long"`
	StoreType               StoreType       `json:"store_type"`
	MiniAppType             MiniAppType     `json:"mini_app_type"`
	ETWStoreType            *ETWStoreType   `json:"etw_store_type,omitempty"`
	ETWMiniAppType          *ETWMiniAppType `json:"etw_mini_app_type,omitempty"`
	StoreID                 *int            `json:"store_id"`
	MainPrice               float64         `json:"main_price"`
	StrikethroughPrice      *float64        `json:"strikethrough_price"`
	Weight                  float64         `json:"weight"`
	StockLeft               int             `json:"stock_left"`
	MinimumOrderQuantity    int             `json:"minimum_order_quantity"`
	IsActive                bool            `json:"is_active"`
	IsFeatured              bool            `json:"is_featured"`
	IsMiniAppRecommendation bool            `json:"is_mini_app_recommendation"`
	ImageUrls               []string        `json:"image_urls"`
	CategoryIds             []string        `json:"category_ids"`
	SubcategoryIds          []string        `json:"subcategory_ids"`
	StockQuantity           *int            `json:"stock_quantity"`
	CreatedAt               time.Time       `json:"created_at"`
	UpdatedAt               time.Time       `json:"updated_at"`
}

// ToPublicProduct converts a Product to PublicProduct (excludes cost_price)
func (p *Product) ToPublicProduct() PublicProduct {
	return PublicProduct{
		ID:                      p.ID,
		UUID:                    p.UUID,
		SKU:                     p.SKU,
		Title:                   p.Title,
		DescriptionShort:        p.DescriptionShort,
		DescriptionLong:         p.DescriptionLong,
		StoreType:               p.StoreType,
		MiniAppType:             p.MiniAppType,
		ETWStoreType:            p.ETWStoreType,
		ETWMiniAppType:          p.ETWMiniAppType,
		StoreID:                 p.StoreID,
		MainPrice:               p.MainPrice,
		StrikethroughPrice:      p.StrikethroughPrice,
		Weight:                  p.Weight,
		StockLeft:               p.StockLeft,
		MinimumOrderQuantity:    p.MinimumOrderQuantity,
		IsActive:                p.IsActive,
		IsFeatured:              p.IsFeatured,
		IsMiniAppRecommendation: p.IsMiniAppRecommendation,
		ImageUrls:               p.ImageUrls,
		CategoryIds:             p.CategoryIds,
		SubcategoryIds:          p.SubcategoryIds,
		StockQuantity:           p.StockQuantity,
		CreatedAt:               p.CreatedAt,
		UpdatedAt:               p.UpdatedAt,
	}
}

// DisplayStock returns the stock quantity with buffer applied (actual - 5)
func (p *Product) DisplayStock() *int {
	// Use StockLeft field instead of legacy StockQuantity
	displayStock := p.StockLeft - 5
	if displayStock < 0 {
		displayStock = 0
	}
	return &displayStock
}

// HasStock returns true if the product has stock available
func (p *Product) HasStock() bool {
	// For ETWtoC (Exhibition Sales) mini-app, always show as having stock
	if p.ETWMiniAppType != nil && *p.ETWMiniAppType == ETWMiniAppTypeETWtoC {
		return true
	}
	// For ETWtoU (Unmanned Store), check actual stock
	displayStock := p.DisplayStock()
	return displayStock != nil && *displayStock > 0
}

// Category represents a product category
type Category struct {
	ID             int             `json:"id" db:"category_id"`
	Name           string          `json:"name" db:"name"`
	ETWStoreType   *ETWStoreType   `json:"etw_store_type" db:"etw_store_type"`
	ETWMiniAppType *ETWMiniAppType `json:"etw_mini_app_type" db:"etw_mini_app_type"`
	StoreID        *int            `json:"store_id" db:"store_id"`
	DisplayOrder   int             `json:"display_order" db:"display_order"`
	IsActive       bool            `json:"is_active" db:"is_active"`
	ImageURL       *string         `json:"image_url" db:"image_url"`
	Subcategories  []Subcategory   `json:"subcategories,omitempty"`
	// Store information (populated when store_id is not null)
	StoreName           *string         `json:"store_name,omitempty"`
	StoreCity           *string         `json:"store_city,omitempty"`
	StoreLatitude       *float64        `json:"store_latitude,omitempty"`
	StoreLongitude      *float64        `json:"store_longitude,omitempty"`
	StoreETWStoreType   *ETWStoreType   `json:"store_etw_store_type,omitempty"`
	StoreETWMiniAppType *ETWMiniAppType `json:"store_etw_mini_app_type,omitempty"`
	CreatedAt           time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt           time.Time       `json:"updated_at" db:"updated_at"`
}

// Subcategory represents a product subcategory
type Subcategory struct {
	ID               int       `json:"id" db:"subcategory_id"`
	ParentCategoryID int       `json:"parent_category_id" db:"parent_category_id"`
	Name             string    `json:"name" db:"name"`
	ImageURL         *string   `json:"image_url" db:"image_url"`
	DisplayOrder     int       `json:"display_order" db:"display_order"`
	IsActive         bool      `json:"is_active" db:"is_active"`
	CreatedAt        time.Time `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time `json:"updated_at" db:"updated_at"`
}

// Store represents a physical store location
type Store struct {
	ID             int             `json:"id" db:"store_id"`
	Name           string          `json:"name" db:"name"`
	City           string          `json:"city" db:"city"`
	Address        string          `json:"address" db:"address"`
	Latitude       float64         `json:"latitude" db:"latitude"`
	Longitude      float64         `json:"longitude" db:"longitude"`
	Type           StoreType       `json:"type" db:"type"`
	ETWStoreType   *ETWStoreType   `json:"etw_store_type,omitempty" db:"etw_store_type"`
	ETWMiniAppType *ETWMiniAppType `json:"etw_mini_app_type,omitempty" db:"etw_mini_app_type"`
	RegionID       *int            `json:"region_id,omitempty" db:"region_id"`
	ImageURL       *string         `json:"image_url" db:"image_url"`
	IsActive       bool            `json:"is_active" db:"is_active"`
	CreatedAt      time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time       `json:"updated_at" db:"updated_at"`
}

// Manufacturer represents a product manufacturer
type Manufacturer struct {
	ID            int       `json:"id" db:"manufacturer_id"`
	CompanyName   string    `json:"company_name" db:"company_name"`
	ContactPerson string    `json:"contact_person" db:"contact_person"`
	ContactEmail  string    `json:"contact_email" db:"contact_email"`
	Address       string    `json:"address" db:"address"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
}

// ProductImage represents a product image with enhanced functionality
type ProductImage struct {
	ID           int       `json:"id" db:"image_id"`
	ProductID    int       `json:"product_id" db:"product_id"`
	ImageURL     string    `json:"image_url" db:"image_url"`
	DisplayOrder int       `json:"display_order" db:"display_order"`
	IsPrimary    bool      `json:"is_primary" db:"is_primary"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

// Inventory represents stock quantity for a product at a specific store
type Inventory struct {
	ID        int       `json:"id" db:"inventory_id"`
	ProductID int       `json:"product_id" db:"product_id"`
	StoreID   int       `json:"store_id" db:"store_id"`
	Quantity  int       `json:"quantity" db:"quantity"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}
