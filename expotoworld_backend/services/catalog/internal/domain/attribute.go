// Package domain contains the core business entities for the catalog service.
package domain

import (
	"time"
)

// ProductAttribute represents a variant attribute for a product.
// Attributes are used to define variant options like "Color: Red" or "Size: Large".
// The display_order field is crucial for maintaining consistent ordering in the UI.
type ProductAttribute struct {
	AttributeID    int32
	ProductID      int32  // FK to admin_products
	AttributeName  string // e.g., "Color", "Size"
	AttributeValue string // e.g., "Red", "Large"
	DisplayOrder   int32  // Order for UI display (NOT alphabetical!)
	CreatedAt      time.Time
}

// CreateAttributeParams contains the parameters for creating a new attribute.
type CreateAttributeParams struct {
	ProductID      int32
	AttributeName  string
	AttributeValue string
	DisplayOrder   int32
}

// UpdateAttributeParams contains the parameters for updating an existing attribute.
type UpdateAttributeParams struct {
	AttributeName  *string
	AttributeValue *string
	DisplayOrder   *int32
}

// AttributeGroup represents a group of attribute values for a single attribute name.
// Used when building the variant_options_index for parent products.
type AttributeGroup struct {
	Name    string          // Attribute name (e.g., "Color")
	Options []VariantOption // Sorted list of options by display_order
}
