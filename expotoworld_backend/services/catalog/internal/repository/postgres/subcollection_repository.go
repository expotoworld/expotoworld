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

// SubcollectionRepository implements the subcollection repository using PostgreSQL.
type SubcollectionRepository struct {
	pool *pgxpool.Pool
}

// NewSubcollectionRepository creates a new subcollection repository.
func NewSubcollectionRepository(pool *pgxpool.Pool) *SubcollectionRepository {
	return &SubcollectionRepository{pool: pool}
}

// Create creates a new subcollection.
func (r *SubcollectionRepository) Create(ctx context.Context, params *domain.CreateSubcollectionParams) (*domain.Subcollection, error) {
	query := `
		INSERT INTO admin_product_subcollection (parent_collection_id, name, image_url, display_order, is_active)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING subcollection_id, parent_collection_id, name, image_url, display_order, is_active, created_at, updated_at`

	var sc domain.Subcollection
	err := r.pool.QueryRow(ctx, query,
		params.CollectionID,
		params.Name,
		params.ImageURL,
		params.DisplayOrder,
		params.IsActive,
	).Scan(
		&sc.SubcollectionID,
		&sc.CollectionID,
		&sc.Name,
		&sc.ImageURL,
		&sc.DisplayOrder,
		&sc.IsActive,
		&sc.CreatedAt,
		&sc.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create subcollection: %w", err)
	}
	return &sc, nil
}

// GetByID retrieves a subcollection by ID.
func (r *SubcollectionRepository) GetByID(ctx context.Context, id int32) (*domain.Subcollection, error) {
	query := `
		SELECT sc.subcollection_id, sc.parent_collection_id, sc.name, sc.image_url, sc.display_order, sc.is_active,
			sc.created_at, sc.updated_at,
			COALESCE((SELECT COUNT(*) FROM admin_product_subcollection_mapping psm WHERE psm.subcollection_id = sc.subcollection_id), 0) as product_count
		FROM admin_product_subcollection sc
		WHERE sc.subcollection_id = $1`

	var sc domain.Subcollection
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&sc.SubcollectionID,
		&sc.CollectionID,
		&sc.Name,
		&sc.ImageURL,
		&sc.DisplayOrder,
		&sc.IsActive,
		&sc.CreatedAt,
		&sc.UpdatedAt,
		&sc.ProductCount,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, domain.ErrSubcollectionNotFound
		}
		return nil, fmt.Errorf("failed to get subcollection: %w", err)
	}
	return &sc, nil
}

// GetByCollectionID retrieves all subcollections for a collection.
func (r *SubcollectionRepository) GetByCollectionID(ctx context.Context, collectionID int32) ([]domain.Subcollection, error) {
	query := `
		SELECT sc.subcollection_id, sc.parent_collection_id, sc.name, sc.image_url, sc.display_order, sc.is_active,
			sc.created_at, sc.updated_at,
			COALESCE((SELECT COUNT(*) FROM admin_product_subcollection_mapping psm WHERE psm.subcollection_id = sc.subcollection_id), 0) as product_count
		FROM admin_product_subcollection sc
		WHERE sc.parent_collection_id = $1
		ORDER BY sc.display_order ASC, sc.subcollection_id ASC`

	rows, err := r.pool.Query(ctx, query, collectionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get subcollections by collection: %w", err)
	}
	defer rows.Close()

	var subcollections []domain.Subcollection
	for rows.Next() {
		var sc domain.Subcollection
		if err := rows.Scan(
			&sc.SubcollectionID,
			&sc.CollectionID,
			&sc.Name,
			&sc.ImageURL,
			&sc.DisplayOrder,
			&sc.IsActive,
			&sc.CreatedAt,
			&sc.UpdatedAt,
			&sc.ProductCount,
		); err != nil {
			return nil, fmt.Errorf("failed to scan subcollection: %w", err)
		}
		subcollections = append(subcollections, sc)
	}
	return subcollections, nil
}

// List retrieves subcollections with filtering and pagination.
func (r *SubcollectionRepository) List(ctx context.Context, filter *domain.SubcollectionFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Subcollection], error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if filter != nil {
		if filter.ParentCollectionID != nil {
			conditions = append(conditions, fmt.Sprintf("sc.parent_collection_id = $%d", argIdx))
			args = append(args, *filter.ParentCollectionID)
			argIdx++
		}
		if filter.IsActive != nil {
			conditions = append(conditions, fmt.Sprintf("sc.is_active = $%d", argIdx))
			args = append(args, *filter.IsActive)
			argIdx++
		}
		if filter.Search != nil && *filter.Search != "" {
			conditions = append(conditions, fmt.Sprintf("sc.name ILIKE $%d", argIdx))
			args = append(args, "%"+*filter.Search+"%")
			argIdx++
		}
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Count query
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM admin_product_subcollection sc %s", whereClause)
	var totalCount int64
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&totalCount); err != nil {
		return nil, fmt.Errorf("failed to count subcollections: %w", err)
	}

	// Data query
	offset := (pagination.Page - 1) * pagination.PageSize
	dataQuery := fmt.Sprintf(`
		SELECT sc.subcollection_id, sc.parent_collection_id, sc.name, sc.image_url, sc.display_order, sc.is_active,
			sc.created_at, sc.updated_at,
			COALESCE((SELECT COUNT(*) FROM admin_product_subcollection_mapping psm WHERE psm.subcollection_id = sc.subcollection_id), 0) as product_count
		FROM admin_product_subcollection sc
		%s
		ORDER BY sc.display_order ASC, sc.subcollection_id ASC
		LIMIT $%d OFFSET $%d`,
		whereClause, argIdx, argIdx+1)

	args = append(args, pagination.PageSize, offset)

	rows, err := r.pool.Query(ctx, dataQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list subcollections: %w", err)
	}
	defer rows.Close()

	var subcollections []domain.Subcollection
	for rows.Next() {
		var sc domain.Subcollection
		if err := rows.Scan(
			&sc.SubcollectionID,
			&sc.CollectionID,
			&sc.Name,
			&sc.ImageURL,
			&sc.DisplayOrder,
			&sc.IsActive,
			&sc.CreatedAt,
			&sc.UpdatedAt,
			&sc.ProductCount,
		); err != nil {
			return nil, fmt.Errorf("failed to scan subcollection: %w", err)
		}
		subcollections = append(subcollections, sc)
	}

	totalPages := int(totalCount) / pagination.PageSize
	if int(totalCount)%pagination.PageSize > 0 {
		totalPages++
	}

	return &repository.PaginatedResult[domain.Subcollection]{
		Items:      subcollections,
		TotalCount: totalCount,
		Page:       pagination.Page,
		PageSize:   pagination.PageSize,
		TotalPages: totalPages,
	}, nil
}

// Update updates a subcollection.
func (r *SubcollectionRepository) Update(ctx context.Context, id int32, params *domain.UpdateSubcollectionParams) error {
	var setClauses []string
	var args []interface{}
	argIdx := 1

	if params.Name != nil {
		setClauses = append(setClauses, fmt.Sprintf("name = $%d", argIdx))
		args = append(args, *params.Name)
		argIdx++
	}
	if params.ImageURL != nil {
		setClauses = append(setClauses, fmt.Sprintf("image_url = $%d", argIdx))
		args = append(args, *params.ImageURL)
		argIdx++
	}
	if params.DisplayOrder != nil {
		setClauses = append(setClauses, fmt.Sprintf("display_order = $%d", argIdx))
		args = append(args, *params.DisplayOrder)
		argIdx++
	}
	if params.IsActive != nil {
		setClauses = append(setClauses, fmt.Sprintf("is_active = $%d", argIdx))
		args = append(args, *params.IsActive)
		argIdx++
	}
	if params.CollectionID != nil {
		setClauses = append(setClauses, fmt.Sprintf("parent_collection_id = $%d", argIdx))
		args = append(args, *params.CollectionID)
		argIdx++
	}

	if len(setClauses) == 0 {
		return nil // nothing to update
	}

	setClauses = append(setClauses, "updated_at = NOW()")

	query := fmt.Sprintf("UPDATE admin_product_subcollection SET %s WHERE subcollection_id = $%d",
		strings.Join(setClauses, ", "), argIdx)
	args = append(args, id)

	result, err := r.pool.Exec(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to update subcollection: %w", err)
	}
	if result.RowsAffected() == 0 {
		return domain.ErrSubcollectionNotFound
	}
	return nil
}

// Delete deletes a subcollection.
func (r *SubcollectionRepository) Delete(ctx context.Context, id int32) error {
	query := "DELETE FROM admin_product_subcollection WHERE subcollection_id = $1"
	result, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete subcollection: %w", err)
	}
	if result.RowsAffected() == 0 {
		return domain.ErrSubcollectionNotFound
	}
	return nil
}

// Move moves a subcollection to a different collection.
func (r *SubcollectionRepository) Move(ctx context.Context, subcollectionID int32, targetCollectionID int32) error {
	// Get the max display_order in the target collection
	var maxOrder int32
	err := r.pool.QueryRow(ctx,
		"SELECT COALESCE(MAX(display_order), 0) FROM admin_product_subcollection WHERE parent_collection_id = $1",
		targetCollectionID,
	).Scan(&maxOrder)
	if err != nil {
		return fmt.Errorf("failed to get max display order: %w", err)
	}

	query := "UPDATE admin_product_subcollection SET parent_collection_id = $1, display_order = $2, updated_at = NOW() WHERE subcollection_id = $3"
	result, err := r.pool.Exec(ctx, query, targetCollectionID, maxOrder+1, subcollectionID)
	if err != nil {
		return fmt.Errorf("failed to move subcollection: %w", err)
	}
	if result.RowsAffected() == 0 {
		return domain.ErrSubcollectionNotFound
	}
	return nil
}

// Reorder updates the display order of subcollections within a collection.
func (r *SubcollectionRepository) Reorder(ctx context.Context, collectionID int32, orderedIDs []int32) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	for i, id := range orderedIDs {
		_, err := tx.Exec(ctx,
			"UPDATE admin_product_subcollection SET display_order = $1, updated_at = NOW() WHERE subcollection_id = $2 AND parent_collection_id = $3",
			i+1, id, collectionID,
		)
		if err != nil {
			return fmt.Errorf("failed to update display order for subcollection %d: %w", id, err)
		}
	}

	return tx.Commit(ctx)
}
