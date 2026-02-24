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

// StoreRepository is a PostgreSQL implementation of StoreRepository.
type StoreRepository struct {
	pool *pgxpool.Pool
}

// NewStoreRepository creates a new PostgreSQL store repository.
func NewStoreRepository(pool *pgxpool.Pool) *StoreRepository {
	return &StoreRepository{pool: pool}
}

// Create creates a new store.
func (r *StoreRepository) Create(ctx context.Context, params *domain.CreateStoreParams) (*domain.Store, error) {
	query := `
		INSERT INTO admin_stores (name, city, address, latitude, longitude, image_url, region_id, etw_store_type, etw_mini_app_type, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING store_id, name, city, address, latitude, longitude, image_url, region_id, etw_store_type, etw_mini_app_type, is_active, created_at, updated_at`

	store := &domain.Store{}
	err := r.pool.QueryRow(ctx, query,
		params.Name, params.City, params.Address, params.Latitude, params.Longitude,
		params.ImageURL, params.RegionID, params.ETWStoreType, params.ETWMiniAppType, params.IsActive,
	).Scan(
		&store.StoreID, &store.Name, &store.City, &store.Address, &store.Latitude, &store.Longitude,
		&store.ImageURL, &store.RegionID, &store.ETWStoreType, &store.ETWMiniAppType, &store.IsActive, &store.CreatedAt, &store.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create store: %w", err)
	}
	return store, nil
}

// GetByID retrieves a store by its ID.
func (r *StoreRepository) GetByID(ctx context.Context, id int32) (*domain.Store, error) {
	query := `SELECT store_id, name, city, address, latitude, longitude, image_url, region_id, etw_store_type, etw_mini_app_type, is_active, created_at, updated_at
		FROM admin_stores WHERE store_id = $1`

	store := &domain.Store{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&store.StoreID, &store.Name, &store.City, &store.Address, &store.Latitude, &store.Longitude,
		&store.ImageURL, &store.RegionID, &store.ETWStoreType, &store.ETWMiniAppType, &store.IsActive, &store.CreatedAt, &store.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, domain.ErrStoreNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get store: %w", err)
	}
	return store, nil
}

// GetByOrganizationID retrieves stores by region ID (organization in this context).
func (r *StoreRepository) GetByOrganizationID(ctx context.Context, regionID int32) ([]domain.Store, error) {
	query := `SELECT store_id, name, city, address, latitude, longitude, image_url, region_id, etw_store_type, etw_mini_app_type, is_active, created_at, updated_at
		FROM admin_stores WHERE region_id = $1 ORDER BY name`

	rows, err := r.pool.Query(ctx, query, regionID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var stores []domain.Store
	for rows.Next() {
		var s domain.Store
		if err := rows.Scan(&s.StoreID, &s.Name, &s.City, &s.Address, &s.Latitude, &s.Longitude,
			&s.ImageURL, &s.RegionID, &s.ETWStoreType, &s.ETWMiniAppType, &s.IsActive, &s.CreatedAt, &s.UpdatedAt); err != nil {
			return nil, err
		}
		stores = append(stores, s)
	}
	return stores, nil
}

// List retrieves stores with filtering and pagination.
func (r *StoreRepository) List(ctx context.Context, filter *domain.StoreFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Store], error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if filter != nil {
		if filter.RegionID != nil {
			conditions = append(conditions, fmt.Sprintf("region_id = $%d", argIdx))
			args = append(args, *filter.RegionID)
			argIdx++
		}
		if filter.ETWStoreType != nil {
			conditions = append(conditions, fmt.Sprintf("etw_store_type = $%d", argIdx))
			args = append(args, *filter.ETWStoreType)
			argIdx++
		}
		if filter.ETWMiniAppType != nil {
			conditions = append(conditions, fmt.Sprintf("etw_mini_app_type = $%d", argIdx))
			args = append(args, *filter.ETWMiniAppType)
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
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM admin_stores %s", whereClause)
	var totalCount int64
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&totalCount); err != nil {
		return nil, err
	}

	// Calculate pagination
	offset := (pagination.Page - 1) * pagination.PageSize
	limit := pagination.PageSize

	// Query with pagination
	dataQuery := fmt.Sprintf(`SELECT store_id, name, city, address, latitude, longitude, image_url, region_id, etw_store_type, etw_mini_app_type, is_active, created_at, updated_at
		FROM admin_stores %s ORDER BY name LIMIT $%d OFFSET $%d`, whereClause, argIdx, argIdx+1)
	args = append(args, limit, offset)

	rows, err := r.pool.Query(ctx, dataQuery, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var stores []domain.Store
	for rows.Next() {
		var s domain.Store
		if err := rows.Scan(&s.StoreID, &s.Name, &s.City, &s.Address, &s.Latitude, &s.Longitude,
			&s.ImageURL, &s.RegionID, &s.ETWStoreType, &s.ETWMiniAppType, &s.IsActive, &s.CreatedAt, &s.UpdatedAt); err != nil {
			return nil, err
		}
		stores = append(stores, s)
	}

	totalPages := int(totalCount) / pagination.PageSize
	if int(totalCount)%pagination.PageSize > 0 {
		totalPages++
	}

	return &repository.PaginatedResult[domain.Store]{
		Items:      stores,
		TotalCount: totalCount,
		Page:       pagination.Page,
		PageSize:   pagination.PageSize,
		TotalPages: totalPages,
	}, nil
}

// Update updates a store.
func (r *StoreRepository) Update(ctx context.Context, id int32, params *domain.UpdateStoreParams) error {
	query := `UPDATE admin_stores SET 
		name = COALESCE($1, name),
		city = COALESCE($2, city),
		address = COALESCE($3, address),
		latitude = COALESCE($4, latitude),
		longitude = COALESCE($5, longitude),
		image_url = COALESCE($6, image_url),
		region_id = COALESCE($7, region_id),
		etw_store_type = COALESCE($8, etw_store_type),
		etw_mini_app_type = COALESCE($9, etw_mini_app_type),
		is_active = COALESCE($10, is_active),
		updated_at = NOW()
		WHERE store_id = $11`

	_, err := r.pool.Exec(ctx, query,
		params.Name, params.City, params.Address, params.Latitude, params.Longitude,
		params.ImageURL, params.RegionID, params.ETWStoreType, params.ETWMiniAppType, params.IsActive, id,
	)
	return err
}

// Delete deletes a store.
func (r *StoreRepository) Delete(ctx context.Context, id int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_stores WHERE store_id = $1", id)
	return err
}

// CountProducts counts the number of products in a store.
func (r *StoreRepository) CountProducts(ctx context.Context, storeID int32) (int64, error) {
	var count int64
	err := r.pool.QueryRow(ctx, "SELECT COUNT(*) FROM admin_product WHERE store_id = $1", storeID).Scan(&count)
	return count, err
}

// CountCategories counts the number of categories in a store.
func (r *StoreRepository) CountCategories(ctx context.Context, storeID int32) (int64, error) {
	var count int64
	err := r.pool.QueryRow(ctx, "SELECT COUNT(*) FROM admin_product_categories WHERE store_id = $1", storeID).Scan(&count)
	return count, err
}

// ============================================================================
// RegionRepository
// ============================================================================

// RegionRepository is a PostgreSQL implementation of RegionRepository.
type RegionRepository struct {
	pool *pgxpool.Pool
}

// NewRegionRepository creates a new PostgreSQL region repository.
func NewRegionRepository(pool *pgxpool.Pool) *RegionRepository {
	return &RegionRepository{pool: pool}
}

// Create creates a new region.
func (r *RegionRepository) Create(ctx context.Context, params *domain.CreateRegionParams) (*domain.Region, error) {
	query := `
		INSERT INTO admin_regions (store_id, name, description)
		VALUES ($1, $2, $3)
		RETURNING region_id, store_id, name, description, created_at, updated_at`

	region := &domain.Region{}
	err := r.pool.QueryRow(ctx, query, params.StoreID, params.Name, params.Description).Scan(
		&region.RegionID, &region.StoreID, &region.Name, &region.Description, &region.CreatedAt, &region.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create region: %w", err)
	}
	return region, nil
}

// GetByID retrieves a region by its ID.
func (r *RegionRepository) GetByID(ctx context.Context, id int32) (*domain.Region, error) {
	query := `SELECT region_id, store_id, name, description, created_at, updated_at
		FROM admin_regions WHERE region_id = $1`

	region := &domain.Region{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&region.RegionID, &region.StoreID, &region.Name, &region.Description, &region.CreatedAt, &region.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, domain.ErrRegionNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get region: %w", err)
	}
	return region, nil
}

// GetByStoreID retrieves all regions for a store.
func (r *RegionRepository) GetByStoreID(ctx context.Context, storeID int32) ([]domain.Region, error) {
	query := `SELECT region_id, store_id, name, description, created_at, updated_at
		FROM admin_regions WHERE store_id = $1 ORDER BY name`

	rows, err := r.pool.Query(ctx, query, storeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var regions []domain.Region
	for rows.Next() {
		var region domain.Region
		if err := rows.Scan(&region.RegionID, &region.StoreID, &region.Name, &region.Description, &region.CreatedAt, &region.UpdatedAt); err != nil {
			return nil, err
		}
		regions = append(regions, region)
	}
	return regions, nil
}

// Update updates a region.
func (r *RegionRepository) Update(ctx context.Context, id int32, params *domain.UpdateRegionParams) error {
	query := `UPDATE admin_regions SET 
		store_id = COALESCE($1, store_id),
		name = COALESCE($2, name),
		description = COALESCE($3, description),
		updated_at = NOW()
		WHERE region_id = $4`

	_, err := r.pool.Exec(ctx, query, params.StoreID, params.Name, params.Description, id)
	return err
}

// Delete deletes a region.
func (r *RegionRepository) Delete(ctx context.Context, id int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_regions WHERE region_id = $1", id)
	return err
}

// List retrieves regions with filtering and pagination.
func (r *RegionRepository) List(ctx context.Context, filter *domain.RegionFilter, pagination repository.Pagination) (*repository.PaginatedResult[domain.Region], error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if filter != nil {
		if filter.StoreID != nil {
			conditions = append(conditions, fmt.Sprintf("store_id = $%d", argIdx))
			args = append(args, *filter.StoreID)
			argIdx++
		}
		if filter.Search != nil && *filter.Search != "" {
			conditions = append(conditions, fmt.Sprintf("(name ILIKE $%d OR description ILIKE $%d)", argIdx, argIdx))
			args = append(args, "%"+*filter.Search+"%")
			argIdx++
		}
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Count
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM admin_regions %s", whereClause)
	var totalCount int64
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&totalCount); err != nil {
		return nil, err
	}

	// Paginate
	offset := (pagination.Page - 1) * pagination.PageSize
	query := fmt.Sprintf(`
		SELECT region_id, store_id, name, description, created_at, updated_at
		FROM admin_regions %s
		ORDER BY name
		LIMIT $%d OFFSET $%d`, whereClause, argIdx, argIdx+1)
	args = append(args, pagination.PageSize, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var regions []domain.Region
	for rows.Next() {
		var region domain.Region
		if err := rows.Scan(&region.RegionID, &region.StoreID, &region.Name, &region.Description, &region.CreatedAt, &region.UpdatedAt); err != nil {
			return nil, err
		}
		regions = append(regions, region)
	}

	totalPages := int(totalCount) / pagination.PageSize
	if int(totalCount)%pagination.PageSize > 0 {
		totalPages++
	}

	return &repository.PaginatedResult[domain.Region]{
		Items:      regions,
		TotalCount: totalCount,
		Page:       pagination.Page,
		PageSize:   pagination.PageSize,
		TotalPages: totalPages,
	}, nil
}

// ListAll retrieves all regions without pagination.
func (r *RegionRepository) ListAll(ctx context.Context) ([]domain.Region, error) {
	query := `SELECT region_id, store_id, name, description, created_at, updated_at
		FROM admin_regions ORDER BY name`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var regions []domain.Region
	for rows.Next() {
		var region domain.Region
		if err := rows.Scan(&region.RegionID, &region.StoreID, &region.Name, &region.Description, &region.CreatedAt, &region.UpdatedAt); err != nil {
			return nil, err
		}
		regions = append(regions, region)
	}
	return regions, nil
}
