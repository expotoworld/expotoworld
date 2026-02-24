// Package domain contains the core business entities for the catalog service.
package domain

import (
	"time"
)

// ProductSpecification represents an Amazon-style product specification.
// Specifications are informational key-value pairs like "Brand: Nike", "Material: Cotton".
// Unlike Attributes (which define variant options), Specifications are purely descriptive.
// They are visible on product detail pages and help customers understand product details.
type ProductSpecification struct {
	SpecificationID int32
	ProductID       int32  // FK to admin_product
	SpecName        string // e.g., "Brand", "Material", "Country of Origin"
	SpecValue       string // e.g., "Nike", "Cotton", "USA"
	DisplayOrder    int32  // Order for UI display
	CreatedAt       time.Time
}

// CreateSpecificationParams contains the parameters for creating a new specification.
type CreateSpecificationParams struct {
	ProductID    int32
	SpecName     string
	SpecValue    string
	DisplayOrder int32
}

// UpdateSpecificationParams contains the parameters for updating an existing specification.
type UpdateSpecificationParams struct {
	SpecName     *string
	SpecValue    *string
	DisplayOrder *int32
}

// BatchCreateSpecificationParams contains parameters for bulk specification creation.
// Used when copying parent specifications to child products.
type BatchCreateSpecificationParams struct {
	ProductID      int32
	Specifications []CreateSpecificationParams
}
