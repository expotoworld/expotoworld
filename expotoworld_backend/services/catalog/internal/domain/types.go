// Package domain contains the core business entities and types for the catalog service.
package domain

// ProductType represents the type of a product in the variant system.
type ProductType string

const (
	ProductTypeStandard ProductType = "standard" // A simple product with no variants
	ProductTypeParent   ProductType = "parent"   // A container product with child variants
	ProductTypeChild    ProductType = "child"    // A variant under a parent product
)

// ProductVisibility represents the visibility state of a product.
type ProductVisibility string

const (
	ProductVisibilityVisible    ProductVisibility = "visible"     // Product is shown in catalogs
	ProductVisibilityNotVisible ProductVisibility = "not_visible" // Product is hidden (e.g., child variants)
)

// ETWStoreType represents the type of ETW store.
type ETWStoreType string

const (
	ETWStoreTypeMega   ETWStoreType = "ETWMega"
	ETWStoreTypeMarket ETWStoreType = "ETWMarket"
	ETWStoreTypeToGO   ETWStoreType = "ETWtoGO"
	ETWStoreTypeXpress ETWStoreType = "ETWXpress"
)

// ETWMiniAppType represents the type of ETW mini-app.
type ETWMiniAppType string

const (
	ETWMiniAppTypeToB ETWMiniAppType = "ETWtoB"
	ETWMiniAppTypeToC ETWMiniAppType = "ETWtoC"
	ETWMiniAppTypeToU ETWMiniAppType = "ETWtoU"
	ETWMiniAppTypeToX ETWMiniAppType = "ETWtoX"
)

// OrgType represents the type of organization.
type OrgType string

const (
	OrgTypeBrand       OrgType = "brand"
	OrgTypeDistributor OrgType = "distributor"
	OrgTypeSupplier    OrgType = "supplier"
)

// VariantOption represents a variant option value with its display order.
// This is used in the variant_options_index JSONB field on parent products.
type VariantOption struct {
	Value        string `json:"value"`
	DisplayOrder int32  `json:"display_order"`
}

// VariantOptionsIndex maps attribute names to their sorted list of variant options.
// Example:
//
//	{
//	  "Color": [{"value": "Red", "display_order": 1}, {"value": "Blue", "display_order": 2}],
//	  "Size": [{"value": "S", "display_order": 10}, {"value": "M", "display_order": 20}]
//	}
type VariantOptionsIndex map[string][]VariantOption
