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

// SubcategoryRepository is a PostgreSQL implementation of SubcategoryRepository.
type SubcategoryRepository struct {
	pool *pgxpool.Pool
}

// NewSubcategoryRepository creates a new PostgreSQL subcategory repository.
func NewSubcategoryRepository(pool *pgxpool.Pool) *SubcategoryRepository {
	return &SubcategoryRepository{pool: pool}
}

// Create creates a new subcategory.
func (r *SubcategoryRepository) Create(ctx context.Context, params *domain.CreateSubcategoryParams) (*domain.Subcategory, error) {
	query := `
		INSERT INTO admin_product_subcategory (parent_category_id, name, image_url, display_order, is_active)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING subcategory_id, parent_category_id, name, image_url, display_order, is_active, created_at, updated_at`

	sub := &domain.Subcategory{}
	err := r.pool.QueryRow(ctx, query,
		params.CategoryID, params.Name, params.ImageURL, params.DisplayOrder, params.IsActive,
	).Scan(
		&sub.SubcategoryID, &sub.CategoryID, &sub.Name, &sub.ImageURL, &sub.DisplayOrder, &sub.IsActive, &sub.CreatedAt, &sub.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create subcategory: %w", err)
	}
	return sub, nil
}

// GetByID retrieves a subcategory by its ID.
func (r *SubcategoryRepository) GetByID(ctx context.Context, id int32) (*domain.Subcategory, error) {
	query := `SELECT subcategory_id, parent_category_id, name, image_url, display_order, is_active, created_at, updated_at
		FROM admin_product_subcategory WHERE subcategory_id = $1`

	sub := &domain.Subcategory{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&sub.SubcategoryID, &sub.CategoryID, &sub.Name, &sub.ImageURL, &sub.DisplayOrder, &sub.IsActive, &sub.CreatedAt, &sub.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, domain.ErrSubcategoryNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get subcategory: %w", err)
	}
	return sub, nil
}

// GetByCategoryID retrieves all subcategories for a category.
func (r *SubcategoryRepository) GetByCategoryID(ctx context.Context, categoryID int32) ([]domain.Subcategory, error) {
	query := `SELECT subcategory_id, parent_category_id, name, image_url, display_order, is_active, created_at, updated_at
		FROM admin_product_subcategory WHERE parent_category_id = $1 ORDER BY display_order`

	rows, err := r.pool.Query(ctx, query, categoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var subcategories []domain.Subcategory
	for rows.Next() {
		var s domain.Subcategory
		if err := rows.Scan(&s.SubcategoryID, &s.CategoryID, &s.Name, &s.ImageURL, &s.DisplayOrder, &s.IsActive, &s.CreatedAt, &s.UpdatedAt); err != nil {
			return nil, err
		}
		subcategories = append(subcategories, s)
	}
	return subcategories, nil
}

// List retrieves subcategories with filtering and pagination.
func (r *SubcategoryRepository) List(ctx context.Context, filter *domain.SubcategoryFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Subcategory], error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if filter != nil {
		if filter.ParentCategoryID != nil {
			conditions = append(conditions, fmt.Sprintf("parent_category_id = $%d", argIdx))
			args = append(args, *filter.ParentCategoryID)
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
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM admin_product_subcategory %s", whereClause)
	var totalCount int64
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&totalCount); err != nil {
		return nil, err
	}

	// Paginate
	offset := (pagination.Page - 1) * pagination.PageSize
	query := fmt.Sprintf(`
		SELECT s.subcategory_id, s.parent_category_id, s.name, s.image_url, s.display_order, s.is_active, s.created_at, s.updated_at,
			COALESCE((SELECT COUNT(*) FROM admin_product_subcategory_mapping psm WHERE psm.subcategory_id = s.subcategory_id), 0) as product_count
		FROM admin_product_subcategory s %s
		ORDER BY s.display_order
		LIMIT $%d OFFSET $%d`, whereClause, argIdx, argIdx+1)
	args = append(args, pagination.PageSize, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var subcategories []domain.Subcategory
	for rows.Next() {
		var s domain.Subcategory
		if err := rows.Scan(&s.SubcategoryID, &s.CategoryID, &s.Name, &s.ImageURL, &s.DisplayOrder, &s.IsActive, &s.CreatedAt, &s.UpdatedAt, &s.ProductCount); err != nil {
			return nil, err
		}
		subcategories = append(subcategories, s)
	}

	totalPages := int(totalCount) / pagination.PageSize
	if int(totalCount)%pagination.PageSize > 0 {
		totalPages++
	}

	return &repository.PaginatedResult[domain.Subcategory]{
		Items:      subcategories,
		TotalCount: totalCount,
		Page:       pagination.Page,
		PageSize:   pagination.PageSize,
		TotalPages: totalPages,
	}, nil
}

// Update updates a subcategory.
func (r *SubcategoryRepository) Update(ctx context.Context, id int32, params *domain.UpdateSubcategoryParams) error {
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

	query := fmt.Sprintf("UPDATE admin_product_subcategory SET %s WHERE subcategory_id = $%d", strings.Join(sets, ", "), argIdx)
	_, err := r.pool.Exec(ctx, query, args...)
	return err
}

// Delete deletes a subcategory.
func (r *SubcategoryRepository) Delete(ctx context.Context, id int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_product_subcategory WHERE subcategory_id = $1", id)
	return err
}

// Move moves a subcategory to a different category.
func (r *SubcategoryRepository) Move(ctx context.Context, id int32, newCategoryID int32) error {
	// Get max display order in the new category
	var maxOrder int32
	err := r.pool.QueryRow(ctx, "SELECT COALESCE(MAX(display_order), 0) FROM admin_product_subcategory WHERE parent_category_id = $1", newCategoryID).Scan(&maxOrder)
	if err != nil {
		return err
	}

	_, err = r.pool.Exec(ctx, "UPDATE admin_product_subcategory SET parent_category_id = $1, display_order = $2, updated_at = NOW() WHERE subcategory_id = $3",
		newCategoryID, maxOrder+1, id)
	return err
}

// Reorder updates the display order of multiple subcategories within a category.
func (r *SubcategoryRepository) Reorder(ctx context.Context, categoryID int32, orderedIDs []int32) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	for i, id := range orderedIDs {
		_, err := tx.Exec(ctx, "UPDATE admin_product_subcategory SET display_order = $1 WHERE subcategory_id = $2 AND parent_category_id = $3", i+1, id, categoryID)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}
