package postgres

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
)

// CategoryRepository is a PostgreSQL implementation of CategoryRepository.
type CategoryRepository struct {
	pool *pgxpool.Pool
}

// NewCategoryRepository creates a new PostgreSQL category repository.
func NewCategoryRepository(pool *pgxpool.Pool) *CategoryRepository {
	return &CategoryRepository{pool: pool}
}

// Create creates a new category.
func (r *CategoryRepository) Create(ctx context.Context, params *domain.CreateCategoryParams) (*domain.Category, error) {
	query := `
		INSERT INTO admin_product_categories (name, image_url, display_order, is_active, store_id, etw_store_type, etw_mini_app_type)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING category_id, name, image_url, display_order, is_active, store_id, etw_store_type, etw_mini_app_type, created_at, updated_at`

	cat := &domain.Category{}
	err := r.pool.QueryRow(ctx, query,
		params.Name, params.ImageURL, params.DisplayOrder, params.IsActive, params.StoreID, params.ETWStoreType, params.ETWMiniAppType,
	).Scan(
		&cat.CategoryID, &cat.Name, &cat.ImageURL, &cat.DisplayOrder, &cat.IsActive, &cat.StoreID, &cat.ETWStoreType, &cat.ETWMiniAppType, &cat.CreatedAt, &cat.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create category: %w", err)
	}
	return cat, nil
}

// GetByID retrieves a category by its ID.
func (r *CategoryRepository) GetByID(ctx context.Context, id int32) (*domain.Category, error) {
	query := `SELECT category_id, name, image_url, display_order, is_active, store_id, etw_store_type, etw_mini_app_type, created_at, updated_at
		FROM admin_product_categories WHERE category_id = $1`

	cat := &domain.Category{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&cat.CategoryID, &cat.Name, &cat.ImageURL, &cat.DisplayOrder, &cat.IsActive, &cat.StoreID, &cat.ETWStoreType, &cat.ETWMiniAppType, &cat.CreatedAt, &cat.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, domain.ErrCategoryNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get category: %w", err)
	}
	return cat, nil
}

// GetWithSubcategories retrieves a category with its subcategories.
func (r *CategoryRepository) GetWithSubcategories(ctx context.Context, id int32) (*domain.CategoryWithSubcategories, error) {
	cat, err := r.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	result := &domain.CategoryWithSubcategories{Category: *cat}

	subQuery := `SELECT subcategory_id, parent_category_id, name, image_url, display_order, is_active, created_at, updated_at
		FROM admin_subcategories WHERE parent_category_id = $1 ORDER BY display_order`

	rows, err := r.pool.Query(ctx, subQuery, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var sub domain.Subcategory
		if err := rows.Scan(&sub.SubcategoryID, &sub.CategoryID, &sub.Name, &sub.ImageURL, &sub.DisplayOrder, &sub.IsActive, &sub.CreatedAt, &sub.UpdatedAt); err != nil {
			return nil, err
		}
		result.Subcategories = append(result.Subcategories, sub)
	}

	return result, nil
}

// List retrieves categories with filtering and pagination.
func (r *CategoryRepository) List(ctx context.Context, filter *domain.CategoryFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Category], error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if filter != nil {
		if filter.StoreID != nil {
			conditions = append(conditions, fmt.Sprintf("store_id = $%d", argIdx))
			args = append(args, *filter.StoreID)
			argIdx++
		}
		if filter.IsActive != nil {
			conditions = append(conditions, fmt.Sprintf("is_active = $%d", argIdx))
			args = append(args, *filter.IsActive)
			argIdx++
		}
		if filter.Search != nil && *filter.Search != "" {
			conditions = append(conditions, fmt.Sprintf("name ILIKE $%d", argIdx))
			args = append(args, "%"+*filter.Search+"%")
			argIdx++
		}
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Count
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM admin_product_categories %s", whereClause)
	var totalCount int64
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&totalCount); err != nil {
		return nil, err
	}

	// Paginate
	offset := (pagination.Page - 1) * pagination.PageSize
	query := fmt.Sprintf(`
		SELECT category_id, name, image_url, display_order, is_active, store_id, etw_store_type, etw_mini_app_type, created_at, updated_at
		FROM admin_product_categories %s
		ORDER BY display_order
		LIMIT $%d OFFSET $%d`, whereClause, argIdx, argIdx+1)
	args = append(args, pagination.PageSize, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var categories []domain.Category
	for rows.Next() {
		var c domain.Category
		if err := rows.Scan(&c.CategoryID, &c.Name, &c.ImageURL, &c.DisplayOrder, &c.IsActive, &c.StoreID, &c.ETWStoreType, &c.ETWMiniAppType, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, err
		}
		categories = append(categories, c)
	}

	totalPages := int(totalCount) / pagination.PageSize
	if int(totalCount)%pagination.PageSize > 0 {
		totalPages++
	}

	return &repository.PaginatedResult[domain.Category]{
		Items:      categories,
		TotalCount: totalCount,
		Page:       pagination.Page,
		PageSize:   pagination.PageSize,
		TotalPages: totalPages,
	}, nil
}

// ListWithCounts retrieves categories with product counts.
func (r *CategoryRepository) ListWithCounts(ctx context.Context, filter *domain.CategoryFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.CategoryWithCounts], error) {
	// Implementation similar to List but with counts
	return nil, nil // TODO: implement if needed
}

// ListAll retrieves all categories without pagination.
func (r *CategoryRepository) ListAll(ctx context.Context, filter *domain.CategoryFilter) ([]domain.Category, error) {
	query := `SELECT category_id, name, image_url, display_order, is_active, store_id, etw_store_type, etw_mini_app_type, created_at, updated_at
		FROM admin_product_categories ORDER BY display_order`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var categories []domain.Category
	for rows.Next() {
		var c domain.Category
		if err := rows.Scan(&c.CategoryID, &c.Name, &c.ImageURL, &c.DisplayOrder, &c.IsActive, &c.StoreID, &c.ETWStoreType, &c.ETWMiniAppType, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, err
		}
		categories = append(categories, c)
	}
	return categories, nil
}

// Update updates a category.
func (r *CategoryRepository) Update(ctx context.Context, id int32, params *domain.UpdateCategoryParams) error {
	var sets []string
	var args []interface{}
	argIdx := 1

	if params.Name != nil {
		sets = append(sets, fmt.Sprintf("name = $%d", argIdx))
		args = append(args, *params.Name)
		argIdx++
	}
	if params.ImageURL != nil {
		sets = append(sets, fmt.Sprintf("image_url = $%d", argIdx))
		args = append(args, *params.ImageURL)
		argIdx++
	}
	if params.DisplayOrder != nil {
		sets = append(sets, fmt.Sprintf("display_order = $%d", argIdx))
		args = append(args, *params.DisplayOrder)
		argIdx++
	}
	if params.IsActive != nil {
		sets = append(sets, fmt.Sprintf("is_active = $%d", argIdx))
		args = append(args, *params.IsActive)
		argIdx++
	}

	if len(sets) == 0 {
		return nil
	}

	sets = append(sets, "updated_at = NOW()")
	args = append(args, id)

	query := fmt.Sprintf("UPDATE admin_product_categories SET %s WHERE category_id = $%d", strings.Join(sets, ", "), argIdx)
	_, err := r.pool.Exec(ctx, query, args...)
	return err
}

// Delete deletes a category.
func (r *CategoryRepository) Delete(ctx context.Context, id int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_product_categories WHERE category_id = $1", id)
	return err
}

// Reorder updates the display order of multiple categories.
func (r *CategoryRepository) Reorder(ctx context.Context, orderedIDs []int32) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	for i, id := range orderedIDs {
		_, err := tx.Exec(ctx, "UPDATE admin_product_categories SET display_order = $1 WHERE category_id = $2", i+1, id)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

// GetCategoryTree retrieves the full category tree.
func (r *CategoryRepository) GetCategoryTree(ctx context.Context, filter *domain.CategoryFilter) ([]domain.CategoryWithSubcategories, error) {
	categories, err := r.ListAll(ctx, filter)
	if err != nil {
		return nil, err
	}

	var result []domain.CategoryWithSubcategories
	for _, cat := range categories {
		catWithSubs, err := r.GetWithSubcategories(ctx, cat.CategoryID)
		if err != nil {
			continue
		}
		result = append(result, *catWithSubs)
	}

	return result, nil
}
