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

// CollectionRepository implements the collection repository using PostgreSQL.
type CollectionRepository struct {
	pool *pgxpool.Pool
}

// NewCollectionRepository creates a new collection repository.
func NewCollectionRepository(pool *pgxpool.Pool) *CollectionRepository {
	return &CollectionRepository{pool: pool}
}

// Create creates a new collection.
func (r *CollectionRepository) Create(ctx context.Context, params *domain.CreateCollectionParams) (*domain.Collection, error) {
	query := `
		INSERT INTO admin_product_collection (parent_subcategory_id, name, image_url, display_order, is_active)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING collection_id, parent_subcategory_id, name, image_url, display_order, is_active, created_at, updated_at`

	var c domain.Collection
	err := r.pool.QueryRow(ctx, query,
		params.SubcategoryID,
		params.Name,
		params.ImageURL,
		params.DisplayOrder,
		params.IsActive,
	).Scan(
		&c.CollectionID,
		&c.SubcategoryID,
		&c.Name,
		&c.ImageURL,
		&c.DisplayOrder,
		&c.IsActive,
		&c.CreatedAt,
		&c.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create collection: %w", err)
	}
	return &c, nil
}

// GetByID retrieves a collection by ID.
func (r *CollectionRepository) GetByID(ctx context.Context, id int32) (*domain.Collection, error) {
	query := `
		SELECT c.collection_id, c.parent_subcategory_id, c.name, c.image_url, c.display_order, c.is_active,
			c.created_at, c.updated_at,
			COALESCE((SELECT COUNT(*) FROM admin_product_collection_mapping pcm WHERE pcm.collection_id = c.collection_id), 0) as product_count
		FROM admin_product_collection c
		WHERE c.collection_id = $1`

	var c domain.Collection
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&c.CollectionID,
		&c.SubcategoryID,
		&c.Name,
		&c.ImageURL,
		&c.DisplayOrder,
		&c.IsActive,
		&c.CreatedAt,
		&c.UpdatedAt,
		&c.ProductCount,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, domain.ErrCollectionNotFound
		}
		return nil, fmt.Errorf("failed to get collection: %w", err)
	}
	return &c, nil
}

// GetBySubcategoryID retrieves all collections for a subcategory.
func (r *CollectionRepository) GetBySubcategoryID(ctx context.Context, subcategoryID int32) ([]domain.Collection, error) {
	query := `
		SELECT c.collection_id, c.parent_subcategory_id, c.name, c.image_url, c.display_order, c.is_active,
			c.created_at, c.updated_at,
			COALESCE((SELECT COUNT(*) FROM admin_product_collection_mapping pcm WHERE pcm.collection_id = c.collection_id), 0) as product_count
		FROM admin_product_collection c
		WHERE c.parent_subcategory_id = $1
		ORDER BY c.display_order ASC, c.collection_id ASC`

	rows, err := r.pool.Query(ctx, query, subcategoryID)
	if err != nil {
		return nil, fmt.Errorf("failed to get collections by subcategory: %w", err)
	}
	defer rows.Close()

	var collections []domain.Collection
	for rows.Next() {
		var c domain.Collection
		if err := rows.Scan(
			&c.CollectionID,
			&c.SubcategoryID,
			&c.Name,
			&c.ImageURL,
			&c.DisplayOrder,
			&c.IsActive,
			&c.CreatedAt,
			&c.UpdatedAt,
			&c.ProductCount,
		); err != nil {
			return nil, fmt.Errorf("failed to scan collection: %w", err)
		}
		collections = append(collections, c)
	}
	return collections, nil
}

// List retrieves collections with filtering and pagination.
func (r *CollectionRepository) List(ctx context.Context, filter *domain.CollectionFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Collection], error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if filter != nil {
		if filter.ParentSubcategoryID != nil {
			conditions = append(conditions, fmt.Sprintf("c.parent_subcategory_id = $%d", argIdx))
			args = append(args, *filter.ParentSubcategoryID)
			argIdx++
		}
		if filter.IsActive != nil {
			conditions = append(conditions, fmt.Sprintf("c.is_active = $%d", argIdx))
			args = append(args, *filter.IsActive)
			argIdx++
		}
		if filter.Search != nil && *filter.Search != "" {
			conditions = append(conditions, fmt.Sprintf("c.name ILIKE $%d", argIdx))
			args = append(args, "%"+*filter.Search+"%")
			argIdx++
		}
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Count query
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM admin_product_collection c %s", whereClause)
	var totalCount int64
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&totalCount); err != nil {
		return nil, fmt.Errorf("failed to count collections: %w", err)
	}

	// Data query
	offset := (pagination.Page - 1) * pagination.PageSize
	dataQuery := fmt.Sprintf(`
		SELECT c.collection_id, c.parent_subcategory_id, c.name, c.image_url, c.display_order, c.is_active,
			c.created_at, c.updated_at,
			COALESCE((SELECT COUNT(*) FROM admin_product_collection_mapping pcm WHERE pcm.collection_id = c.collection_id), 0) as product_count
		FROM admin_product_collection c
		%s
		ORDER BY c.display_order ASC, c.collection_id ASC
		LIMIT $%d OFFSET $%d`,
		whereClause, argIdx, argIdx+1)

	args = append(args, pagination.PageSize, offset)

	rows, err := r.pool.Query(ctx, dataQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list collections: %w", err)
	}
	defer rows.Close()

	var collections []domain.Collection
	for rows.Next() {
		var c domain.Collection
		if err := rows.Scan(
			&c.CollectionID,
			&c.SubcategoryID,
			&c.Name,
			&c.ImageURL,
			&c.DisplayOrder,
			&c.IsActive,
			&c.CreatedAt,
			&c.UpdatedAt,
			&c.ProductCount,
		); err != nil {
			return nil, fmt.Errorf("failed to scan collection: %w", err)
		}
		collections = append(collections, c)
	}

	totalPages := int(totalCount) / pagination.PageSize
	if int(totalCount)%pagination.PageSize > 0 {
		totalPages++
	}

	return &repository.PaginatedResult[domain.Collection]{
		Items:      collections,
		TotalCount: totalCount,
		Page:       pagination.Page,
		PageSize:   pagination.PageSize,
		TotalPages: totalPages,
	}, nil
}

// Update updates a collection.
func (r *CollectionRepository) Update(ctx context.Context, id int32, params *domain.UpdateCollectionParams) error {
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
	if params.SubcategoryID != nil {
		setClauses = append(setClauses, fmt.Sprintf("parent_subcategory_id = $%d", argIdx))
		args = append(args, *params.SubcategoryID)
		argIdx++
	}

	if len(setClauses) == 0 {
		return nil // nothing to update
	}

	setClauses = append(setClauses, "updated_at = NOW()")

	query := fmt.Sprintf("UPDATE admin_product_collection SET %s WHERE collection_id = $%d",
		strings.Join(setClauses, ", "), argIdx)
	args = append(args, id)

	result, err := r.pool.Exec(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to update collection: %w", err)
	}
	if result.RowsAffected() == 0 {
		return domain.ErrCollectionNotFound
	}
	return nil
}

// Delete deletes a collection.
func (r *CollectionRepository) Delete(ctx context.Context, id int32) error {
	query := "DELETE FROM admin_product_collection WHERE collection_id = $1"
	result, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete collection: %w", err)
	}
	if result.RowsAffected() == 0 {
		return domain.ErrCollectionNotFound
	}
	return nil
}

// Move moves a collection to a different subcategory.
func (r *CollectionRepository) Move(ctx context.Context, collectionID int32, targetSubcategoryID int32) error {
	// Get the max display_order in the target subcategory
	var maxOrder int32
	err := r.pool.QueryRow(ctx,
		"SELECT COALESCE(MAX(display_order), 0) FROM admin_product_collection WHERE parent_subcategory_id = $1",
		targetSubcategoryID,
	).Scan(&maxOrder)
	if err != nil {
		return fmt.Errorf("failed to get max display order: %w", err)
	}

	query := "UPDATE admin_product_collection SET parent_subcategory_id = $1, display_order = $2, updated_at = NOW() WHERE collection_id = $3"
	result, err := r.pool.Exec(ctx, query, targetSubcategoryID, maxOrder+1, collectionID)
	if err != nil {
		return fmt.Errorf("failed to move collection: %w", err)
	}
	if result.RowsAffected() == 0 {
		return domain.ErrCollectionNotFound
	}
	return nil
}

// Reorder updates the display order of collections within a subcategory.
func (r *CollectionRepository) Reorder(ctx context.Context, subcategoryID int32, orderedIDs []int32) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	for i, id := range orderedIDs {
		_, err := tx.Exec(ctx,
			"UPDATE admin_product_collection SET display_order = $1, updated_at = NOW() WHERE collection_id = $2 AND parent_subcategory_id = $3",
			i+1, id, subcategoryID,
		)
		if err != nil {
			return fmt.Errorf("failed to update display order for collection %d: %w", id, err)
		}
	}

	return tx.Commit(ctx)
}
