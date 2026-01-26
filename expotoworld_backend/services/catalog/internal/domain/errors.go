// Package domain contains the core business entities for the catalog service.
package domain

import "errors"

// Domain-specific errors for the catalog service.
var (
	// Product errors
	ErrProductNotFound           = errors.New("product not found")
	ErrProductAlreadyExists      = errors.New("product with this SKU already exists")
	ErrInvalidProductType        = errors.New("invalid product type")
	ErrInvalidVisibility         = errors.New("invalid product visibility")
	ErrChildMustHaveParent       = errors.New("child product must have a parent ID")
	ErrParentCannotHaveParent    = errors.New("parent product cannot have a parent ID")
	ErrStandardCannotHaveParent  = errors.New("standard product cannot have a parent ID")
	ErrChildCannotBeVisible      = errors.New("child product cannot be visible")
	ErrParentNotFound            = errors.New("parent product not found")
	ErrParentNotParentType       = errors.New("referenced parent is not a parent type product")
	ErrCannotArchiveWithChildren = errors.New("cannot archive product with active children")
	ErrProductArchived           = errors.New("product is archived")
	ErrDuplicateSKU              = errors.New("SKU already exists for another active product")
	ErrInvalidShelfCode          = errors.New("shelf code already exists for this store")
	ErrNoVariantOptions          = errors.New("parent product has no variant options defined")
	ErrNotParentProduct          = errors.New("product is not a parent type")
	ErrVariantNotBelongToParent  = errors.New("one or more variants do not belong to the specified parent")

	// Category errors
	ErrCategoryNotFound         = errors.New("category not found")
	ErrCategoryAlreadyExists    = errors.New("category with this name already exists")
	ErrCategoryHasProducts      = errors.New("category has associated products")
	ErrCategoryHasSubcategories = errors.New("category has subcategories")

	// Subcategory errors
	ErrSubcategoryNotFound      = errors.New("subcategory not found")
	ErrSubcategoryAlreadyExists = errors.New("subcategory with this name already exists in the category")
	ErrSubcategoryHasProducts   = errors.New("subcategory has associated products")
	ErrInvalidParentCategory    = errors.New("invalid parent category")

	// Store errors
	ErrStoreNotFound      = errors.New("store not found")
	ErrStoreAlreadyExists = errors.New("store with this name already exists")
	ErrStoreHasProducts   = errors.New("store has associated products")

	// Image errors
	ErrImageNotFound    = errors.New("image not found")
	ErrMaxImagesReached = errors.New("maximum number of images reached")

	// Attribute errors
	ErrAttributeNotFound      = errors.New("attribute not found")
	ErrAttributeAlreadyExists = errors.New("attribute already exists for this product")
	ErrInvalidAttributeValue  = errors.New("invalid attribute value")

	// Specification errors
	ErrSpecificationNotFound      = errors.New("specification not found")
	ErrSpecificationAlreadyExists = errors.New("specification already exists for this product")

	// Region errors
	ErrRegionNotFound = errors.New("region not found")

	// Organization errors
	ErrOrganizationNotFound = errors.New("organization not found")
	ErrInvalidOrgType       = errors.New("invalid organization type")

	// Pagination errors
	ErrInvalidPageNumber = errors.New("invalid page number")
	ErrInvalidPageSize   = errors.New("invalid page size")

	// Validation errors
	ErrValidationFailed = errors.New("validation failed")
	ErrInvalidInput     = errors.New("invalid input")
)

// ValidationError represents a validation error with field-level details.
type ValidationError struct {
	Field   string
	Message string
}

// ValidationErrors is a collection of validation errors.
type ValidationErrors []ValidationError

// Error implements the error interface.
func (ve ValidationErrors) Error() string {
	if len(ve) == 0 {
		return "validation failed"
	}
	return ve[0].Field + ": " + ve[0].Message
}

// Add adds a new validation error.
func (ve *ValidationErrors) Add(field, message string) {
	*ve = append(*ve, ValidationError{Field: field, Message: message})
}

// HasErrors returns true if there are any validation errors.
func (ve ValidationErrors) HasErrors() bool {
	return len(ve) > 0
}

// NotFoundError wraps a not found error with additional context.
type NotFoundError struct {
	Entity string
	ID     interface{}
}

// Error implements the error interface.
func (e *NotFoundError) Error() string {
	return e.Entity + " not found"
}

// Is checks if the target error matches.
func (e *NotFoundError) Is(target error) bool {
	switch target {
	case ErrProductNotFound:
		return e.Entity == "product"
	case ErrCategoryNotFound:
		return e.Entity == "category"
	case ErrSubcategoryNotFound:
		return e.Entity == "subcategory"
	case ErrStoreNotFound:
		return e.Entity == "store"
	case ErrImageNotFound:
		return e.Entity == "image"
	case ErrAttributeNotFound:
		return e.Entity == "attribute"
	case ErrRegionNotFound:
		return e.Entity == "region"
	case ErrOrganizationNotFound:
		return e.Entity == "organization"
	}
	return false
}

// NewNotFoundError creates a new NotFoundError.
func NewNotFoundError(entity string, id interface{}) *NotFoundError {
	return &NotFoundError{Entity: entity, ID: id}
}
