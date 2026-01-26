package service

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
)

// CategoryService provides business logic for categories and subcategories.
type CategoryService struct {
	pool            *pgxpool.Pool
	categoryRepo    repository.CategoryRepository
	subcategoryRepo repository.SubcategoryRepository
	categoryMapping repository.CategoryMappingRepository
	subcatMapping   repository.SubcategoryMappingRepository
}

// NewCategoryService creates a new category service.
func NewCategoryService(
	pool *pgxpool.Pool,
	categoryRepo repository.CategoryRepository,
	subcategoryRepo repository.SubcategoryRepository,
	categoryMapping repository.CategoryMappingRepository,
	subcatMapping repository.SubcategoryMappingRepository,
) *CategoryService {
	return &CategoryService{
		pool:            pool,
		categoryRepo:    categoryRepo,
		subcategoryRepo: subcategoryRepo,
		categoryMapping: categoryMapping,
		subcatMapping:   subcatMapping,
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
// Also removes all product mappings.
func (s *CategoryService) DeleteCategory(ctx context.Context, id int32) error {
	// Get subcategories first
	subcats, err := s.subcategoryRepo.GetByCategoryID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get subcategories: %w", err)
	}

	// Delete subcategory mappings
	for _, sub := range subcats {
		if err := s.subcatMapping.DeleteBySubcategoryID(ctx, sub.SubcategoryID); err != nil {
			return fmt.Errorf("failed to delete subcategory mappings: %w", err)
		}
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

// DeleteSubcategory deletes a subcategory and its product mappings.
func (s *CategoryService) DeleteSubcategory(ctx context.Context, id int32) error {
	// Delete mappings first
	if err := s.subcatMapping.DeleteBySubcategoryID(ctx, id); err != nil {
		return fmt.Errorf("failed to delete mappings: %w", err)
	}
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
