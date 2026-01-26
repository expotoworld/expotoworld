// Package domain contains the core business entities for the catalog service.
package domain

import (
	"time"
)

// ProductImage represents an image associated with a product.
type ProductImage struct {
	ImageID      int32
	ProductID    *int32 // FK to admin_products
	ImageURL     *string
	DisplayOrder int32
	IsPrimary    bool // Whether this is the primary/main image
	CreatedAt    time.Time
}

// CreateImageParams contains the parameters for creating a new product image.
type CreateImageParams struct {
	ProductID    int32
	ImageURL     string
	DisplayOrder int32
	IsPrimary    bool
}

// UpdateImageParams contains the parameters for updating an existing image.
type UpdateImageParams struct {
	ImageURL     *string
	DisplayOrder *int32
	IsPrimary    *bool
}

// ReorderImagesParams contains the parameters for reordering product images.
type ReorderImagesParams struct {
	ProductID int32
	ImageIDs  []int32 // Image IDs in the new display order
}
