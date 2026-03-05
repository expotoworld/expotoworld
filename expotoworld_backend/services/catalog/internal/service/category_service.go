package service

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
)

// CategoryService provides business logic for categories, subcategories, collections, and subcollections.
type CategoryService struct {
	pool                 *pgxpool.Pool
	categoryRepo         repository.CategoryRepository
	subcategoryRepo      repository.SubcategoryRepository
	collectionRepo       repository.CollectionRepository
	subcollectionRepo    repository.SubcollectionRepository
	categoryMapping      repository.CategoryMappingRepository
	subcatMapping        repository.SubcategoryMappingRepository
	collectionMapping    repository.CollectionMappingRepository
	subcollectionMapping repository.SubcollectionMappingRepository
}

// NewCategoryService creates a new category service.
func NewCategoryService(
	pool *pgxpool.Pool,
	categoryRepo repository.CategoryRepository,
	subcategoryRepo repository.SubcategoryRepository,
	collectionRepo repository.CollectionRepository,
	subcollectionRepo repository.SubcollectionRepository,
	categoryMapping repository.CategoryMappingRepository,
	subcatMapping repository.SubcategoryMappingRepository,
	collectionMapping repository.CollectionMappingRepository,
	subcollectionMapping repository.SubcollectionMappingRepository,
) *CategoryService {
	return &CategoryService{
		pool:                 pool,
		categoryRepo:         categoryRepo,
		subcategoryRepo:      subcategoryRepo,
		collectionRepo:       collectionRepo,
		subcollectionRepo:    subcollectionRepo,
		categoryMapping:      categoryMapping,
		subcatMapping:        subcatMapping,
		collectionMapping:    collectionMapping,
		subcollectionMapping: subcollectionMapping,
	}
}

// CreateCategory creates a new category.
func (s *CategoryService) CreateCategory(ctx context.Context, params *domain.CreateCategoryParams) (*domain.Category, error) {
	return s.categoryRepo.Create(ctx, params)
}

// GetCategory retrieves a category by ID.
func (s *CategoryService) GetCategory(ctx context.Context, id int32) (*domain.Category, error) {
	return s.categoryRepo.GetByID(ctx, id)
}

// GetCategoryWithSubcategories retrieves a category with its subcategories.
func (s *CategoryService) GetCategoryWithSubcategories(ctx context.Context, id int32) (*domain.CategoryWithSubcategories, error) {
	return s.categoryRepo.GetWithSubcategories(ctx, id)
}

// ListCategories lists categories with filtering and pagination.
func (s *CategoryService) ListCategories(ctx context.Context, filter *domain.CategoryFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Category], error) {
	return s.categoryRepo.List(ctx, filter, pagination)
}

// GetCategoryTree retrieves the complete category tree for a store/platform.
func (s *CategoryService) GetCategoryTree(ctx context.Context, filter *domain.CategoryFilter) ([]domain.CategoryWithSubcategories, error) {
	return s.categoryRepo.GetCategoryTree(ctx, filter)
}

// UpdateCategory updates a category.
func (s *CategoryService) UpdateCategory(ctx context.Context, id int32, params *domain.UpdateCategoryParams) (*domain.Category, error) {
	if err := s.categoryRepo.Update(ctx, id, params); err != nil {
		return nil, err
	}
	return s.categoryRepo.GetByID(ctx, id)
}

// DeleteCategory deletes a category and its subcategories.
// Also removes all product mappings (including collection and subcollection mappings).
func (s *CategoryService) DeleteCategory(ctx context.Context, id int32) error {
	// Get subcategories first
	subcats, err := s.subcategoryRepo.GetByCategoryID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get subcategories: %w", err)
	}

	// Delete subcategory + collection + subcollection mappings
	for _, sub := range subcats {
		// Get collections for this subcategory
		collections, err := s.collectionRepo.GetBySubcategoryID(ctx, sub.SubcategoryID)
		if err != nil {
			return fmt.Errorf("failed to get collections for subcategory %d: %w", sub.SubcategoryID, err)
		}
		// Delete subcollection and collection mappings
		for _, col := range collections {
			// Delete subcollection mappings for subcollections under this collection
			subcollections, err := s.subcollectionRepo.GetByCollectionID(ctx, col.CollectionID)
			if err != nil {
				return fmt.Errorf("failed to get subcollections for collection %d: %w", col.CollectionID, err)
			}
			for _, sc := range subcollections {
				if err := s.subcollectionMapping.DeleteBySubcollectionID(ctx, sc.SubcollectionID); err != nil {
					return fmt.Errorf("failed to delete subcollection mappings: %w", err)
				}
			}
			if err := s.collectionMapping.DeleteByCollectionID(ctx, col.CollectionID); err != nil {
				return fmt.Errorf("failed to delete collection mappings: %w", err)
			}
		}
		// Delete subcategory mappings
		if err := s.subcatMapping.DeleteBySubcategoryID(ctx, sub.SubcategoryID); err != nil {
			return fmt.Errorf("failed to delete subcategory mappings: %w", err)
		}
		// Collections are deleted by CASCADE when subcategory is deleted
		if err := s.subcategoryRepo.Delete(ctx, sub.SubcategoryID); err != nil {
			return fmt.Errorf("failed to delete subcategory %d: %w", sub.SubcategoryID, err)
		}
	}

	// Delete category mappings
	if err := s.categoryMapping.DeleteByCategoryID(ctx, id); err != nil {
		return fmt.Errorf("failed to delete category mappings: %w", err)
	}

	// Delete category
	return s.categoryRepo.Delete(ctx, id)
}

// ReorderCategories updates the display order of categories.
func (s *CategoryService) ReorderCategories(ctx context.Context, orderedIDs []int32) error {
	return s.categoryRepo.Reorder(ctx, orderedIDs)
}

// CreateSubcategory creates a new subcategory.
func (s *CategoryService) CreateSubcategory(ctx context.Context, params *domain.CreateSubcategoryParams) (*domain.Subcategory, error) {
	// Verify parent category exists
	if _, err := s.categoryRepo.GetByID(ctx, params.CategoryID); err != nil {
		return nil, fmt.Errorf("parent category not found: %w", err)
	}
	return s.subcategoryRepo.Create(ctx, params)
}

// GetSubcategory retrieves a subcategory by ID.
func (s *CategoryService) GetSubcategory(ctx context.Context, id int32) (*domain.Subcategory, error) {
	return s.subcategoryRepo.GetByID(ctx, id)
}

// ListSubcategories lists subcategories with filtering and pagination.
func (s *CategoryService) ListSubcategories(ctx context.Context, filter *domain.SubcategoryFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Subcategory], error) {
	return s.subcategoryRepo.List(ctx, filter, pagination)
}

// GetSubcategoriesByCategory retrieves all subcategories for a category.
func (s *CategoryService) GetSubcategoriesByCategory(ctx context.Context, categoryID int32) ([]domain.Subcategory, error) {
	return s.subcategoryRepo.GetByCategoryID(ctx, categoryID)
}

// UpdateSubcategory updates a subcategory.
func (s *CategoryService) UpdateSubcategory(ctx context.Context, id int32, params *domain.UpdateSubcategoryParams) (*domain.Subcategory, error) {
	if err := s.subcategoryRepo.Update(ctx, id, params); err != nil {
		return nil, err
	}
	return s.subcategoryRepo.GetByID(ctx, id)
}

// DeleteSubcategory deletes a subcategory, its collections, subcollections, and their product mappings.
func (s *CategoryService) DeleteSubcategory(ctx context.Context, id int32) error {
	// Get collections under this subcategory
	collections, err := s.collectionRepo.GetBySubcategoryID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get collections: %w", err)
	}
	// Delete subcollection and collection mappings
	for _, col := range collections {
		subcollections, err := s.subcollectionRepo.GetByCollectionID(ctx, col.CollectionID)
		if err != nil {
			return fmt.Errorf("failed to get subcollections for collection %d: %w", col.CollectionID, err)
		}
		for _, sc := range subcollections {
			if err := s.subcollectionMapping.DeleteBySubcollectionID(ctx, sc.SubcollectionID); err != nil {
				return fmt.Errorf("failed to delete subcollection mappings: %w", err)
			}
		}
		if err := s.collectionMapping.DeleteByCollectionID(ctx, col.CollectionID); err != nil {
			return fmt.Errorf("failed to delete collection mappings: %w", err)
		}
	}
	// Delete subcategory mappings
	if err := s.subcatMapping.DeleteBySubcategoryID(ctx, id); err != nil {
		return fmt.Errorf("failed to delete mappings: %w", err)
	}
	// Collections + subcollections are deleted by CASCADE when subcategory is deleted
	return s.subcategoryRepo.Delete(ctx, id)
}

// MoveSubcategory moves a subcategory to a different category.
func (s *CategoryService) MoveSubcategory(ctx context.Context, subcategoryID int32, targetCategoryID int32) error {
	// Verify target category exists
	if _, err := s.categoryRepo.GetByID(ctx, targetCategoryID); err != nil {
		return fmt.Errorf("target category not found: %w", err)
	}
	return s.subcategoryRepo.Move(ctx, subcategoryID, targetCategoryID)
}

// ReorderSubcategories updates the display order of subcategories within a category.
func (s *CategoryService) ReorderSubcategories(ctx context.Context, categoryID int32, orderedIDs []int32) error {
	return s.subcategoryRepo.Reorder(ctx, categoryID, orderedIDs)
}

// ----------------------------------------------------------------
// Collection methods
// ----------------------------------------------------------------

// CreateCollection creates a new collection under a subcategory.
func (s *CategoryService) CreateCollection(ctx context.Context, params *domain.CreateCollectionParams) (*domain.Collection, error) {
	// Verify parent subcategory exists
	if _, err := s.subcategoryRepo.GetByID(ctx, params.SubcategoryID); err != nil {
		return nil, fmt.Errorf("parent subcategory not found: %w", err)
	}
	return s.collectionRepo.Create(ctx, params)
}

// GetCollection retrieves a collection by ID.
func (s *CategoryService) GetCollection(ctx context.Context, id int32) (*domain.Collection, error) {
	return s.collectionRepo.GetByID(ctx, id)
}

// ListCollections lists collections with filtering and pagination.
func (s *CategoryService) ListCollections(ctx context.Context, filter *domain.CollectionFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Collection], error) {
	return s.collectionRepo.List(ctx, filter, pagination)
}

// GetCollectionsBySubcategory retrieves all collections for a subcategory.
func (s *CategoryService) GetCollectionsBySubcategory(ctx context.Context, subcategoryID int32) ([]domain.Collection, error) {
	return s.collectionRepo.GetBySubcategoryID(ctx, subcategoryID)
}

// UpdateCollection updates a collection.
func (s *CategoryService) UpdateCollection(ctx context.Context, id int32, params *domain.UpdateCollectionParams) (*domain.Collection, error) {
	if err := s.collectionRepo.Update(ctx, id, params); err != nil {
		return nil, err
	}
	col, err := s.collectionRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return col, nil
}

// DeleteCollection deletes a collection, its subcollections, and their product mappings.
func (s *CategoryService) DeleteCollection(ctx context.Context, id int32) error {
	// Delete subcollection mappings first
	subcollections, err := s.subcollectionRepo.GetByCollectionID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get subcollections: %w", err)
	}
	for _, sc := range subcollections {
		if err := s.subcollectionMapping.DeleteBySubcollectionID(ctx, sc.SubcollectionID); err != nil {
			return fmt.Errorf("failed to delete subcollection mappings: %w", err)
		}
	}
	// Delete collection mappings
	if err := s.collectionMapping.DeleteByCollectionID(ctx, id); err != nil {
		return fmt.Errorf("failed to delete collection mappings: %w", err)
	}
	// Subcollections are deleted by CASCADE when collection is deleted
	return s.collectionRepo.Delete(ctx, id)
}

// MoveCollection moves a collection to a different subcategory.
func (s *CategoryService) MoveCollection(ctx context.Context, collectionID int32, targetSubcategoryID int32) error {
	// Verify target subcategory exists
	if _, err := s.subcategoryRepo.GetByID(ctx, targetSubcategoryID); err != nil {
		return fmt.Errorf("target subcategory not found: %w", err)
	}
	return s.collectionRepo.Move(ctx, collectionID, targetSubcategoryID)
}

// ReorderCollections updates the display order of collections within a subcategory.
func (s *CategoryService) ReorderCollections(ctx context.Context, subcategoryID int32, orderedIDs []int32) error {
	return s.collectionRepo.Reorder(ctx, subcategoryID, orderedIDs)
}

// GetCategoryTreeFull retrieves the full 4-tier category tree (categories → subcategories → collections → subcollections).
func (s *CategoryService) GetCategoryTreeFull(ctx context.Context, filter *domain.CategoryFilter) ([]domain.CategoryWithFullHierarchy, error) {
	// Get the 2-tier tree first
	tree, err := s.categoryRepo.GetCategoryTree(ctx, filter)
	if err != nil {
		return nil, err
	}

	// Enrich each subcategory with its collections and subcollections
	var result []domain.CategoryWithFullHierarchy
	for _, cat := range tree {
		fullCat := domain.CategoryWithFullHierarchy{
			Category: cat.Category,
		}
		for _, sub := range cat.Subcategories {
			collections, err := s.collectionRepo.GetBySubcategoryID(ctx, sub.SubcategoryID)
			if err != nil {
				return nil, fmt.Errorf("failed to get collections for subcategory %d: %w", sub.SubcategoryID, err)
			}
			var collectionsWithSubs []domain.CollectionWithSubcollections
			for _, col := range collections {
				subcollections, err := s.subcollectionRepo.GetByCollectionID(ctx, col.CollectionID)
				if err != nil {
					return nil, fmt.Errorf("failed to get subcollections for collection %d: %w", col.CollectionID, err)
				}
				collectionsWithSubs = append(collectionsWithSubs, domain.CollectionWithSubcollections{
					Collection:     col,
					Subcollections: subcollections,
				})
			}
			fullCat.Subcategories = append(fullCat.Subcategories, domain.SubcategoryWithCollections{
				Subcategory: sub,
				Collections: collectionsWithSubs,
			})
		}
		result = append(result, fullCat)
	}
	return result, nil
}

// ----------------------------------------------------------------
// Subcollection methods
// ----------------------------------------------------------------

// CreateSubcollection creates a new subcollection under a collection.
func (s *CategoryService) CreateSubcollection(ctx context.Context, params *domain.CreateSubcollectionParams) (*domain.Subcollection, error) {
	// Verify parent collection exists
	if _, err := s.collectionRepo.GetByID(ctx, params.CollectionID); err != nil {
		return nil, fmt.Errorf("parent collection not found: %w", err)
	}
	return s.subcollectionRepo.Create(ctx, params)
}

// GetSubcollection retrieves a subcollection by ID.
func (s *CategoryService) GetSubcollection(ctx context.Context, id int32) (*domain.Subcollection, error) {
	return s.subcollectionRepo.GetByID(ctx, id)
}

// ListSubcollections lists subcollections with filtering and pagination.
func (s *CategoryService) ListSubcollections(ctx context.Context, filter *domain.SubcollectionFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Subcollection], error) {
	return s.subcollectionRepo.List(ctx, filter, pagination)
}

// GetSubcollectionsByCollection retrieves all subcollections for a collection.
func (s *CategoryService) GetSubcollectionsByCollection(ctx context.Context, collectionID int32) ([]domain.Subcollection, error) {
	return s.subcollectionRepo.GetByCollectionID(ctx, collectionID)
}

// UpdateSubcollection updates a subcollection.
func (s *CategoryService) UpdateSubcollection(ctx context.Context, id int32, params *domain.UpdateSubcollectionParams) (*domain.Subcollection, error) {
	if err := s.subcollectionRepo.Update(ctx, id, params); err != nil {
		return nil, err
	}
	return s.subcollectionRepo.GetByID(ctx, id)
}

// DeleteSubcollection deletes a subcollection and its product mappings.
func (s *CategoryService) DeleteSubcollection(ctx context.Context, id int32) error {
	// Delete subcollection mappings first
	if err := s.subcollectionMapping.DeleteBySubcollectionID(ctx, id); err != nil {
		return fmt.Errorf("failed to delete subcollection mappings: %w", err)
	}
	return s.subcollectionRepo.Delete(ctx, id)
}

// MoveSubcollection moves a subcollection to a different collection.
func (s *CategoryService) MoveSubcollection(ctx context.Context, subcollectionID int32, targetCollectionID int32) error {
	// Verify target collection exists
	if _, err := s.collectionRepo.GetByID(ctx, targetCollectionID); err != nil {
		return fmt.Errorf("target collection not found: %w", err)
	}
	return s.subcollectionRepo.Move(ctx, subcollectionID, targetCollectionID)
}

// ReorderSubcollections updates the display order of subcollections within a collection.
func (s *CategoryService) ReorderSubcollections(ctx context.Context, collectionID int32, orderedIDs []int32) error {
	return s.subcollectionRepo.Reorder(ctx, collectionID, orderedIDs)
}
