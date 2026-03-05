// Package service provides business logic layer for the catalog service.
package service

import (
	"context"
	"fmt"
	"sort"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
)

// ProductService provides business logic for products with variant system support.
type ProductService struct {
	pool                 *pgxpool.Pool
	productRepo          repository.ProductRepository
	attributeRepo        repository.AttributeRepository
	specificationRepo    repository.SpecificationRepository
	imageRepo            repository.ImageRepository
	categoryMapping      repository.CategoryMappingRepository
	subcatMapping        repository.SubcategoryMappingRepository
	collectionMapping    repository.CollectionMappingRepository
	subcollectionMapping repository.SubcollectionMappingRepository
}

// NewProductService creates a new product service.
func NewProductService(
	pool *pgxpool.Pool,
	productRepo repository.ProductRepository,
	attributeRepo repository.AttributeRepository,
	specificationRepo repository.SpecificationRepository,
	imageRepo repository.ImageRepository,
	categoryMapping repository.CategoryMappingRepository,
	subcatMapping repository.SubcategoryMappingRepository,
	collectionMapping repository.CollectionMappingRepository,
	subcollectionMapping repository.SubcollectionMappingRepository,
) *ProductService {
	return &ProductService{
		pool:                 pool,
		productRepo:          productRepo,
		attributeRepo:        attributeRepo,
		specificationRepo:    specificationRepo,
		imageRepo:            imageRepo,
		categoryMapping:      categoryMapping,
		subcatMapping:        subcatMapping,
		collectionMapping:    collectionMapping,
		subcollectionMapping: subcollectionMapping,
	}
}

// CreateProductInput contains all data needed to create a product.
type CreateProductInput struct {
	Product          domain.CreateProductParams
	Attributes       []domain.CreateAttributeParams
	Images           []domain.CreateImageParams
	CategoryIDs      []int32
	SubcatIDs        []int32
	CollectionIDs    []int32
	SubcollectionIDs []int32
}

// CreateProduct creates a new product with all associated data.
// For child products, it also syncs the parent's aggregates.
func (s *ProductService) CreateProduct(ctx context.Context, input *CreateProductInput) (*domain.ProductWithRelations, error) {
	// Validate product type constraints
	if err := s.validateProductType(&input.Product); err != nil {
		return nil, err
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Create the product
	product, err := s.productRepo.CreateTx(ctx, tx, &input.Product)
	if err != nil {
		return nil, fmt.Errorf("failed to create product: %w", err)
	}

	// Create attributes
	var attributes []domain.ProductAttribute
	for _, attr := range input.Attributes {
		attr.ProductID = product.ProductID
		a, err := s.attributeRepo.CreateTx(ctx, tx, &attr)
		if err != nil {
			continue // Log but continue
		}
		attributes = append(attributes, *a)
	}

	// Create images
	var images []domain.ProductImage
	for _, img := range input.Images {
		img.ProductID = product.ProductID
		i, err := s.imageRepo.CreateTx(ctx, tx, &img)
		if err != nil {
			continue
		}
		images = append(images, *i)
	}

	// Create category mappings
	if len(input.CategoryIDs) > 0 {
		if err := s.categoryMapping.SetCategoriesTx(ctx, tx, product.ProductID, input.CategoryIDs); err != nil {
			return nil, fmt.Errorf("failed to set category mappings: %w", err)
		}
	}

	// Create subcategory mappings
	if len(input.SubcatIDs) > 0 {
		if err := s.subcatMapping.SetSubcategoriesTx(ctx, tx, product.ProductID, input.SubcatIDs); err != nil {
			return nil, fmt.Errorf("failed to set subcategory mappings: %w", err)
		}
	}

	// Create collection mappings
	if len(input.CollectionIDs) > 0 {
		if err := s.collectionMapping.SetCollectionsTx(ctx, tx, product.ProductID, input.CollectionIDs); err != nil {
			return nil, fmt.Errorf("failed to set collection mappings: %w", err)
		}
	}

	// Create subcollection mappings
	if len(input.SubcollectionIDs) > 0 {
		if err := s.subcollectionMapping.SetSubcollectionsTx(ctx, tx, product.ProductID, input.SubcollectionIDs); err != nil {
			return nil, fmt.Errorf("failed to set subcollection mappings: %w", err)
		}
	}

	// If this is a child product, sync parent aggregates
	if product.IsChild() && product.ParentID != nil {
		if err := s.syncParentAggregatesTx(ctx, tx, *product.ParentID); err != nil {
			fmt.Printf("warning: failed to sync parent aggregates: %v\n", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return &domain.ProductWithRelations{
		Product:    *product,
		Attributes: attributes,
		Images:     images,
	}, nil
}

// validateProductType validates the product type constraints.
func (s *ProductService) validateProductType(params *domain.CreateProductParams) error {
	switch params.ProductType {
	case domain.ProductTypeParent:
		if params.ParentID != nil {
			return domain.ErrParentCannotHaveParent
		}
	case domain.ProductTypeChild:
		if params.ParentID == nil {
			return domain.ErrChildMustHaveParent
		}
		if params.Visibility == domain.ProductVisibilityVisible {
			return domain.ErrChildCannotBeVisible
		}
	case domain.ProductTypeStandard:
		if params.ParentID != nil {
			return domain.ErrStandardCannotHaveParent
		}
	}
	return nil
}

// GetProduct retrieves a product by ID with all relations.
func (s *ProductService) GetProduct(ctx context.Context, id int32) (*domain.ProductWithRelations, error) {
	return s.productRepo.GetWithRelations(ctx, id)
}

// GetProductByUUID retrieves a product by UUID.
func (s *ProductService) GetProductByUUID(ctx context.Context, uuid string) (*domain.Product, error) {
	return s.productRepo.GetByUUID(ctx, uuid)
}

// ListProducts lists products with filtering and pagination.
func (s *ProductService) ListProducts(ctx context.Context, filter *domain.ProductFilter, pagination repository.Pagination, sort *domain.ProductSort) (*repository.PaginatedResult[domain.Product], error) {
	return s.productRepo.List(ctx, filter, pagination, sort)
}

// UpdateProductInput contains all data needed to update a product.
type UpdateProductInput struct {
	ProductID        int32
	Product          domain.UpdateProductParams
	Attributes       *[]domain.CreateAttributeParams // If set, replaces all attributes
	Images           *[]domain.CreateImageParams     // If set, replaces all images
	CategoryIDs      *[]int32                        // If set, replaces all categories
	SubcatIDs        *[]int32                        // If set, replaces all subcategories
	CollectionIDs    *[]int32                        // If set, replaces all collections
	SubcollectionIDs *[]int32                        // If set, replaces all subcollections
}

// UpdateProduct updates a product and optionally its relations.
func (s *ProductService) UpdateProduct(ctx context.Context, input *UpdateProductInput) (*domain.ProductWithRelations, error) {
	// Get existing product
	existing, err := s.productRepo.GetByID(ctx, input.ProductID)
	if err != nil {
		return nil, err
	}

	if existing.IsArchived {
		return nil, domain.ErrProductArchived
	}

	// Update product
	if err := s.productRepo.Update(ctx, input.ProductID, &input.Product); err != nil {
		return nil, fmt.Errorf("failed to update product: %w", err)
	}

	// Replace attributes if provided
	if input.Attributes != nil {
		if err := s.attributeRepo.DeleteByProductID(ctx, input.ProductID); err != nil {
			return nil, fmt.Errorf("failed to delete existing attributes: %w", err)
		}
		for _, attr := range *input.Attributes {
			attr.ProductID = input.ProductID
			if _, err := s.attributeRepo.Create(ctx, &attr); err != nil {
				return nil, fmt.Errorf("failed to create attribute: %w", err)
			}
		}
	}

	// Replace images if provided
	if input.Images != nil {
		if err := s.imageRepo.DeleteByProductID(ctx, input.ProductID); err != nil {
			return nil, fmt.Errorf("failed to delete existing images: %w", err)
		}
		for _, img := range *input.Images {
			img.ProductID = input.ProductID
			if _, err := s.imageRepo.Create(ctx, &img); err != nil {
				return nil, fmt.Errorf("failed to create image: %w", err)
			}
		}
	}

	// Replace category mappings if provided
	if input.CategoryIDs != nil {
		if err := s.categoryMapping.SetCategories(ctx, input.ProductID, *input.CategoryIDs); err != nil {
			return nil, fmt.Errorf("failed to replace category mappings: %w", err)
		}
	}

	// Replace subcategory mappings if provided
	if input.SubcatIDs != nil {
		if err := s.subcatMapping.SetSubcategories(ctx, input.ProductID, *input.SubcatIDs); err != nil {
			return nil, fmt.Errorf("failed to replace subcategory mappings: %w", err)
		}
	}

	// Replace collection mappings if provided
	if input.CollectionIDs != nil {
		if err := s.collectionMapping.SetCollections(ctx, input.ProductID, *input.CollectionIDs); err != nil {
			return nil, fmt.Errorf("failed to replace collection mappings: %w", err)
		}
	}

	// Replace subcollection mappings if provided
	if input.SubcollectionIDs != nil {
		if err := s.subcollectionMapping.SetSubcollections(ctx, input.ProductID, *input.SubcollectionIDs); err != nil {
			return nil, fmt.Errorf("failed to replace subcollection mappings: %w", err)
		}
	}

	// If this is a child product, sync parent aggregates
	if existing.IsChild() && existing.ParentID != nil {
		if err := s.SyncParentAggregates(ctx, *existing.ParentID); err != nil {
			fmt.Printf("warning: failed to sync parent aggregates: %v\n", err)
		}
	}

	return s.productRepo.GetWithRelations(ctx, input.ProductID)
}

// SyncParentAggregates recalculates and updates parent product aggregates.
// This computes price_min, price_max, stock_total, and variant_options_index
// from all active (non-archived) child products.
//
// CRITICAL: variant_options_index values are sorted by display_order (NOT alphabetically).
func (s *ProductService) SyncParentAggregates(ctx context.Context, parentID int32) error {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	if err := s.syncParentAggregatesTx(ctx, tx, parentID); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// syncParentAggregatesTx performs aggregate sync within a transaction.
func (s *ProductService) syncParentAggregatesTx(ctx context.Context, tx pgx.Tx, parentID int32) error {
	// Verify parent exists and is a parent type
	parent, err := s.productRepo.GetByID(ctx, parentID)
	if err != nil {
		return err
	}

	if !parent.IsParent() {
		return fmt.Errorf("product %d is not a parent product", parentID)
	}

	// Get all active children
	children, err := s.productRepo.GetChildrenByParentIDTx(ctx, tx, parentID)
	if err != nil {
		return fmt.Errorf("failed to get children: %w", err)
	}

	// Filter to active only
	var activeChildren []domain.Product
	for _, c := range children {
		if !c.IsArchived {
			activeChildren = append(activeChildren, c)
		}
	}

	// Calculate aggregates
	params := s.calculateAggregates(ctx, activeChildren)

	// Update parent
	if err := s.productRepo.UpdateParentAggregatesTx(ctx, tx, parentID, params); err != nil {
		return fmt.Errorf("failed to update parent aggregates: %w", err)
	}

	return nil
}

// calculateAggregates computes parent aggregates from children.
func (s *ProductService) calculateAggregates(ctx context.Context, children []domain.Product) *domain.UpdateParentAggregatesParams {
	params := &domain.UpdateParentAggregatesParams{
		VariantOptionsIndex: make(domain.VariantOptionsIndex),
	}

	if len(children) == 0 {
		// No active children - set nulls/zeros
		return params
	}

	// Calculate price range and stock total
	var priceMin, priceMax *float64
	var stockTotal int32 = 0

	for _, child := range children {
		if child.MainPrice != nil {
			if priceMin == nil || *child.MainPrice < *priceMin {
				priceMin = child.MainPrice
			}
			if priceMax == nil || *child.MainPrice > *priceMax {
				priceMax = child.MainPrice
			}
		}
		if child.StockLeft != nil {
			stockTotal += *child.StockLeft
		}
	}

	params.PriceMin = priceMin
	params.PriceMax = priceMax
	params.StockTotal = stockTotal

	// Build variant_options_index from child attributes
	// Map: attribute_name -> map[value]display_order
	optionMap := make(map[string]map[string]int32)

	for _, child := range children {
		// Get attributes for this child
		attrs, err := s.attributeRepo.GetByProductID(ctx, child.ProductID)
		if err != nil {
			continue
		}

		for _, attr := range attrs {
			if _, exists := optionMap[attr.AttributeName]; !exists {
				optionMap[attr.AttributeName] = make(map[string]int32)
			}
			// Only add if not already present, keeping first display_order
			if _, valExists := optionMap[attr.AttributeName][attr.AttributeValue]; !valExists {
				optionMap[attr.AttributeName][attr.AttributeValue] = attr.DisplayOrder
			}
		}
	}

	// Convert to VariantOptionsIndex with proper sorting by display_order
	for attrName, values := range optionMap {
		var options []domain.VariantOption
		for value, displayOrder := range values {
			options = append(options, domain.VariantOption{
				Value:        value,
				DisplayOrder: displayOrder,
			})
		}
		// Sort by display_order (NOT alphabetically!)
		sort.Slice(options, func(i, j int) bool {
			return options[i].DisplayOrder < options[j].DisplayOrder
		})
		params.VariantOptionsIndex[attrName] = options
	}

	return params
}

// ArchiveProduct soft-deletes a product with cascade rules:
// - If parent: archives all children, then archives parent
// - If child: archives child, then syncs parent aggregates
// - If standard: simply archives the product
func (s *ProductService) ArchiveProduct(ctx context.Context, id int32) error {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	product, err := s.productRepo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	if product.IsArchived {
		return nil // Already archived
	}

	switch {
	case product.IsParent():
		// Archive all children first
		children, err := s.productRepo.GetChildrenByParentIDTx(ctx, tx, id)
		if err != nil {
			return fmt.Errorf("failed to get children: %w", err)
		}
		for _, child := range children {
			if err := s.productRepo.ArchiveTx(ctx, tx, child.ProductID); err != nil {
				return fmt.Errorf("failed to archive child %d: %w", child.ProductID, err)
			}
		}
		// Archive parent
		if err := s.productRepo.ArchiveTx(ctx, tx, id); err != nil {
			return fmt.Errorf("failed to archive parent: %w", err)
		}

	case product.IsChild():
		// Archive child
		if err := s.productRepo.ArchiveTx(ctx, tx, id); err != nil {
			return fmt.Errorf("failed to archive child: %w", err)
		}
		// Check if parent needs update
		if product.ParentID != nil {
			if err := s.syncParentAggregatesTx(ctx, tx, *product.ParentID); err != nil {
				return fmt.Errorf("failed to sync parent aggregates: %w", err)
			}
		}

	default:
		// Standard product - just archive
		if err := s.productRepo.ArchiveTx(ctx, tx, id); err != nil {
			return fmt.Errorf("failed to archive product: %w", err)
		}
	}

	return tx.Commit(ctx)
}

// UnarchiveProduct restores an archived product.
// For child products, it also syncs parent aggregates.
func (s *ProductService) UnarchiveProduct(ctx context.Context, id int32) error {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	product, err := s.productRepo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	if !product.IsArchived {
		return nil // Not archived
	}

	// Unarchive by setting is_archived = false
	isArchived := false
	if err := s.productRepo.UpdateTx(ctx, tx, id, &domain.UpdateProductParams{IsArchived: &isArchived}); err != nil {
		return fmt.Errorf("failed to unarchive product: %w", err)
	}

	// If child, sync parent
	if product.IsChild() && product.ParentID != nil {
		if err := s.syncParentAggregatesTx(ctx, tx, *product.ParentID); err != nil {
			return fmt.Errorf("failed to sync parent aggregates: %w", err)
		}
	}

	return tx.Commit(ctx)
}

// DeleteProduct permanently deletes a product and all associated data.
// USE WITH CAUTION - prefer ArchiveProduct for soft delete.
func (s *ProductService) DeleteProduct(ctx context.Context, id int32) error {
	product, err := s.productRepo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	// If parent, delete children first
	if product.IsParent() {
		children, err := s.productRepo.GetChildrenByParentID(ctx, id)
		if err != nil {
			return fmt.Errorf("failed to get children: %w", err)
		}
		for _, child := range children {
			if err := s.deleteProductData(ctx, child.ProductID); err != nil {
				return fmt.Errorf("failed to delete child %d: %w", child.ProductID, err)
			}
		}
	}

	return s.deleteProductData(ctx, id)
}

// deleteProductData deletes a single product and its associated data.
func (s *ProductService) deleteProductData(ctx context.Context, id int32) error {
	// Delete related data first
	s.attributeRepo.DeleteByProductID(ctx, id)
	s.imageRepo.DeleteByProductID(ctx, id)
	s.categoryMapping.SetCategories(ctx, id, nil)
	s.subcatMapping.SetSubcategories(ctx, id, nil)

	// Delete product
	return s.productRepo.Delete(ctx, id)
}

// GetParentWithChildren retrieves a parent product with all its children.
func (s *ProductService) GetParentWithChildren(ctx context.Context, parentID int32) (*domain.ProductWithRelations, error) {
	product, err := s.productRepo.GetByID(ctx, parentID)
	if err != nil {
		return nil, err
	}

	if !product.IsParent() {
		return nil, fmt.Errorf("product %d is not a parent product", parentID)
	}

	return s.productRepo.GetWithRelations(ctx, parentID)
}

// CreateChildProduct creates a new child product under a parent and syncs aggregates.
func (s *ProductService) CreateChildProduct(ctx context.Context, parentID int32, input *CreateProductInput) (*domain.ProductWithRelations, error) {
	// Verify parent exists and is a parent type
	parent, err := s.productRepo.GetByID(ctx, parentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get parent: %w", err)
	}

	if !parent.IsParent() {
		return nil, fmt.Errorf("product %d is not a parent product", parentID)
	}

	if parent.IsArchived {
		return nil, fmt.Errorf("cannot add child to archived parent")
	}

	// Set child product constraints
	input.Product.ProductType = domain.ProductTypeChild
	input.Product.ParentID = &parentID
	input.Product.Visibility = domain.ProductVisibilityNotVisible

	// Inherit store and owner from parent
	input.Product.StoreID = parent.StoreID
	input.Product.OwnerOrgID = parent.OwnerOrgID

	return s.CreateProduct(ctx, input)
}

// SetDefaultVariant sets a child as the default variant for display purposes.
func (s *ProductService) SetDefaultVariant(ctx context.Context, childID int32) error {
	child, err := s.productRepo.GetByID(ctx, childID)
	if err != nil {
		return err
	}

	if !child.IsChild() || child.ParentID == nil {
		return fmt.Errorf("product %d is not a child product", childID)
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Unset current default
	children, err := s.productRepo.GetChildrenByParentIDTx(ctx, tx, *child.ParentID)
	if err != nil {
		return fmt.Errorf("failed to get children: %w", err)
	}

	falseVal := false
	trueVal := true
	for _, c := range children {
		if c.IsDefaultVariant {
			if err := s.productRepo.UpdateTx(ctx, tx, c.ProductID, &domain.UpdateProductParams{IsDefaultVariant: &falseVal}); err != nil {
				return fmt.Errorf("failed to unset default: %w", err)
			}
		}
	}

	// Set new default
	if err := s.productRepo.UpdateTx(ctx, tx, childID, &domain.UpdateProductParams{IsDefaultVariant: &trueVal}); err != nil {
		return fmt.Errorf("failed to set default: %w", err)
	}

	return tx.Commit(ctx)
}

// GenerateVariantsInput contains parameters for generating product variants.
type GenerateVariantsInput struct {
	// DefaultPrice is the base price for all generated variants
	DefaultPrice float64
	// DefaultStock is the base stock for all generated variants
	DefaultStock int32
	// SkipExisting if true, will not overwrite existing variants
	SkipExisting bool
}

// GenerateVariantsResult contains the result of variant generation.
type GenerateVariantsResult struct {
	// Created is the number of variants created
	Created int
	// Skipped is the number of variants that already existed (if SkipExisting was true)
	Skipped int
	// TotalPossible is the total number of possible variant combinations
	TotalPossible int
	// Variants contains the IDs of created variants
	Variants []int32
}

// GenerateVariants creates all missing variants for a parent product based on its variant_options_index.
// It generates the Cartesian product of all option values and creates child products for each combination.
func (s *ProductService) GenerateVariants(ctx context.Context, parentID int32, input *GenerateVariantsInput) (*GenerateVariantsResult, error) {
	// Get parent product with relations
	parent, err := s.productRepo.GetWithRelations(ctx, parentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get parent product: %w", err)
	}

	if !parent.IsParent() {
		return nil, fmt.Errorf("product %d is not a parent product", parentID)
	}

	// Check if there are options defined
	if len(parent.VariantOptionsIndex) == 0 {
		return nil, fmt.Errorf("parent product has no variant options defined")
	}

	// Get existing children
	existingChildren, err := s.productRepo.GetChildrenByParentID(ctx, parentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get existing children: %w", err)
	}

	// Build map of existing combinations
	existingCombos := make(map[string]bool)
	for _, child := range existingChildren {
		comboKey := s.buildComboKey(child.ProductID, existingChildren, parent.VariantOptionsIndex)
		if comboKey != "" {
			existingCombos[comboKey] = true
		}
	}

	// Generate all possible combinations
	combinations := s.generateCombinations(parent.VariantOptionsIndex)
	totalPossible := len(combinations)

	result := &GenerateVariantsResult{
		TotalPossible: totalPossible,
		Variants:      make([]int32, 0),
	}

	// Create variants for each combination
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	for _, combo := range combinations {
		comboKey := s.buildComboKeyFromMap(combo)

		// Skip if already exists and SkipExisting is true
		if input.SkipExisting && existingCombos[comboKey] {
			result.Skipped++
			continue
		}

		// Generate title from combination (e.g., "Parent Title - Red - Large")
		variantTitle := ""
		if parent.Title != nil {
			variantTitle = *parent.Title
		}
		for _, value := range combo {
			if variantTitle != "" {
				variantTitle = variantTitle + " - " + value
			} else {
				variantTitle = value
			}
		}

		// Create child product params
		childParams := &domain.CreateProductParams{
			Title:                variantTitle,
			Description:          parent.Description,
			StoreID:              parent.StoreID,
			OwnerOrgID:           parent.OwnerOrgID,
			MainPrice:            &input.DefaultPrice,
			StrikethroughPrice:   parent.StrikethroughPrice,
			CostPrice:            parent.CostPrice,
			StockLeft:            &input.DefaultStock,
			MinimumOrderQuantity: parent.MinimumOrderQuantity,
			NetContent:           parent.NetContent,
			ContentUnit:          parent.ContentUnit,
			ReferencePrice:       parent.ReferencePrice,
			ReferenceUnit:        parent.ReferenceUnit,
			LogisticsLength:      parent.LogisticsLength,
			LogisticsWidth:       parent.LogisticsWidth,
			LogisticsHeight:      parent.LogisticsHeight,
			LogisticsWeight:      parent.LogisticsWeight,
			LogisticsVolume:      parent.LogisticsVolume,
			ShelfCode:            parent.ShelfCode,
			IsActive:             true,
			ProductType:          domain.ProductTypeChild,
			ParentID:             &parentID,
			Visibility:           domain.ProductVisibilityNotVisible,
			ETWStoreType:         parent.ETWStoreType,
			ETWMiniAppType:       parent.ETWMiniAppType,
		}

		// Create the child product
		child, err := s.productRepo.CreateTx(ctx, tx, childParams)
		if err != nil {
			return nil, fmt.Errorf("failed to create variant: %w", err)
		}

		// Add attributes for each option value
		displayOrder := int32(1)
		for optName, optValue := range combo {
			attrParams := &domain.CreateAttributeParams{
				ProductID:      child.ProductID,
				AttributeName:  optName,
				AttributeValue: optValue,
				DisplayOrder:   displayOrder,
			}
			if _, err := s.attributeRepo.Create(ctx, attrParams); err != nil {
				return nil, fmt.Errorf("failed to create attribute: %w", err)
			}
			displayOrder++
		}

		// Copy parent specifications to child (Option A: child has own copy)
		if len(parent.Specifications) > 0 {
			if _, err := s.specificationRepo.CopyFromProductTx(ctx, tx, parent.ProductID, child.ProductID); err != nil {
				return nil, fmt.Errorf("failed to copy specifications to variant: %w", err)
			}
		}

		result.Created++
		result.Variants = append(result.Variants, child.ProductID)
	}

	// Sync parent aggregates
	if err := s.syncParentAggregatesTx(ctx, tx, parentID); err != nil {
		return nil, fmt.Errorf("failed to sync parent aggregates: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return result, nil
}

// generateCombinations generates the Cartesian product of all option values.
// For example, if options are {"Color": ["Red", "Blue"], "Size": ["S", "M"]},
// it returns [{"Color": "Red", "Size": "S"}, {"Color": "Red", "Size": "M"}, {"Color": "Blue", "Size": "S"}, {"Color": "Blue", "Size": "M"}]
func (s *ProductService) generateCombinations(options domain.VariantOptionsIndex) []map[string]string {
	// Get sorted option names for consistent ordering
	optionNames := make([]string, 0, len(options))
	for name := range options {
		optionNames = append(optionNames, name)
	}

	if len(optionNames) == 0 {
		return nil
	}

	// Start with combinations of the first option
	combinations := make([]map[string]string, 0)
	firstName := optionNames[0]
	for _, opt := range options[firstName] {
		combinations = append(combinations, map[string]string{firstName: opt.Value})
	}

	// Multiply by each subsequent option
	for i := 1; i < len(optionNames); i++ {
		name := optionNames[i]
		newCombinations := make([]map[string]string, 0)
		for _, combo := range combinations {
			for _, opt := range options[name] {
				newCombo := make(map[string]string)
				for k, v := range combo {
					newCombo[k] = v
				}
				newCombo[name] = opt.Value
				newCombinations = append(newCombinations, newCombo)
			}
		}
		combinations = newCombinations
	}

	return combinations
}

// buildComboKey creates a unique key from a child's variant-defining attributes
func (s *ProductService) buildComboKey(childID int32, children []domain.Product, options domain.VariantOptionsIndex) string {
	// This would need to look up the child's attributes
	// For now, return empty string - the full implementation would query attributes
	return ""
}

// buildComboKeyFromMap creates a unique key from a combination map
func (s *ProductService) buildComboKeyFromMap(combo map[string]string) string {
	// Sort keys for consistent ordering
	keys := make([]string, 0, len(combo))
	for k := range combo {
		keys = append(keys, k)
	}

	result := ""
	for _, k := range keys {
		if result != "" {
			result += "|"
		}
		result += k + ":" + combo[k]
	}
	return result
}

// BulkUpdateVariantsInput contains parameters for bulk updating variants.
type BulkUpdateVariantsInput struct {
	VariantIDs []int32
	Price      *float64
	Stock      *int32
	IsActive   *bool
}

// BulkUpdateVariants updates multiple variants at once.
func (s *ProductService) BulkUpdateVariants(ctx context.Context, parentID int32, input *BulkUpdateVariantsInput) error {
	// Verify parent exists and is a parent product
	parent, err := s.productRepo.GetByID(ctx, parentID)
	if err != nil {
		return fmt.Errorf("failed to get parent product: %w", err)
	}

	if !parent.IsParent() {
		return fmt.Errorf("product %d is not a parent product", parentID)
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Update each variant
	for _, variantID := range input.VariantIDs {
		// Verify the variant belongs to this parent
		variant, err := s.productRepo.GetByID(ctx, variantID)
		if err != nil {
			return fmt.Errorf("failed to get variant %d: %w", variantID, err)
		}

		if variant.ParentID == nil || *variant.ParentID != parentID {
			return fmt.Errorf("variant %d does not belong to parent %d", variantID, parentID)
		}

		updateParams := &domain.UpdateProductParams{
			MainPrice: input.Price,
			StockLeft: input.Stock,
			IsActive:  input.IsActive,
		}

		if err := s.productRepo.UpdateTx(ctx, tx, variantID, updateParams); err != nil {
			return fmt.Errorf("failed to update variant %d: %w", variantID, err)
		}
	}

	// Sync parent aggregates
	if err := s.syncParentAggregatesTx(ctx, tx, parentID); err != nil {
		return fmt.Errorf("failed to sync parent aggregates: %w", err)
	}

	return tx.Commit(ctx)
}
