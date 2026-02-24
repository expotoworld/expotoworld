// Package postgres provides PostgreSQL implementations of repository interfaces.
package postgres

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
)

// ProductRepository is a PostgreSQL implementation of ProductRepository.
type ProductRepository struct {
	pool *pgxpool.Pool
}

// NewProductRepository creates a new PostgreSQL product repository.
func NewProductRepository(pool *pgxpool.Pool) *ProductRepository {
	return &ProductRepository{pool: pool}
}

// Create creates a new product.
func (r *ProductRepository) Create(ctx context.Context, params *domain.CreateProductParams) (*domain.Product, error) {
	return r.createProduct(ctx, r.pool, params)
}

// CreateTx creates a new product within a transaction.
func (r *ProductRepository) CreateTx(ctx context.Context, tx pgx.Tx, params *domain.CreateProductParams) (*domain.Product, error) {
	return r.createProduct(ctx, tx, params)
}

type querier interface {
	QueryRow(ctx context.Context, sql string, args ...interface{}) pgx.Row
	Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error)
	Exec(ctx context.Context, sql string, args ...interface{}) (pgconn.CommandTag, error)
}

func (r *ProductRepository) createProduct(ctx context.Context, q querier, params *domain.CreateProductParams) (*domain.Product, error) {
	query := `
		INSERT INTO admin_product (
			sku, title, description, store_id, owner_org_id,
			main_price, strikethrough_price, cost_price, tax_rate, stock_left,
			minimum_order_quantity, net_content, content_unit, reference_price, reference_unit,
			logistics_length, logistics_width, logistics_height, logistics_weight, logistics_volume,
			shelf_code, is_active, is_featured, is_mini_app_recommendation,
			product_type, parent_id, visibility,
			is_default_variant, etw_store_type, etw_mini_app_type
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
			$16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30
		) RETURNING 
			product_id, product_uuid, sku, title, description,
			store_id, owner_org_id, main_price, strikethrough_price,
			cost_price, tax_rate, stock_left, minimum_order_quantity, net_content,
			content_unit, reference_price, reference_unit,
			logistics_length, logistics_width, logistics_height, logistics_weight, logistics_volume,
			shelf_code, is_active, is_featured, is_mini_app_recommendation,
			is_archived, product_type, parent_id, visibility,
			is_default_variant, price_min, price_max,
			stock_total, variant_options_index, etw_store_type,
			etw_mini_app_type, created_at, updated_at`

	product := &domain.Product{}
	var variantOptionsJSON []byte

	err := q.QueryRow(ctx, query,
		params.SKU, params.Title, params.Description, params.StoreID, params.OwnerOrgID,
		params.MainPrice, params.StrikethroughPrice, params.CostPrice, params.TaxRate, params.StockLeft,
		params.MinimumOrderQuantity, params.NetContent, params.ContentUnit, params.ReferencePrice, params.ReferenceUnit,
		params.LogisticsLength, params.LogisticsWidth, params.LogisticsHeight, params.LogisticsWeight, params.LogisticsVolume,
		params.ShelfCode, params.IsActive, params.IsFeatured, params.IsMiniAppRecommendation,
		params.ProductType, params.ParentID, params.Visibility,
		params.IsDefaultVariant, params.ETWStoreType, params.ETWMiniAppType,
	).Scan(
		&product.ProductID, &product.ProductUUID, &product.SKU, &product.Title, &product.Description,
		&product.StoreID, &product.OwnerOrgID, &product.MainPrice, &product.StrikethroughPrice,
		&product.CostPrice, &product.TaxRate, &product.StockLeft, &product.MinimumOrderQuantity, &product.NetContent,
		&product.ContentUnit, &product.ReferencePrice, &product.ReferenceUnit,
		&product.LogisticsLength, &product.LogisticsWidth, &product.LogisticsHeight, &product.LogisticsWeight, &product.LogisticsVolume,
		&product.ShelfCode, &product.IsActive, &product.IsFeatured, &product.IsMiniAppRecommendation,
		&product.IsArchived, &product.ProductType, &product.ParentID, &product.Visibility,
		&product.IsDefaultVariant, &product.PriceMin, &product.PriceMax,
		&product.StockTotal, &variantOptionsJSON, &product.ETWStoreType,
		&product.ETWMiniAppType, &product.CreatedAt, &product.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create product: %w", err)
	}

	if len(variantOptionsJSON) > 0 {
		if err := json.Unmarshal(variantOptionsJSON, &product.VariantOptionsIndex); err != nil {
			return nil, fmt.Errorf("failed to unmarshal variant options: %w", err)
		}
	}

	return product, nil
}

// GetByID retrieves a product by its ID.
func (r *ProductRepository) GetByID(ctx context.Context, id int32) (*domain.Product, error) {
	return r.getProduct(ctx, r.pool, "product_id = $1", id)
}

// GetByUUID retrieves a product by its UUID.
func (r *ProductRepository) GetByUUID(ctx context.Context, uuid string) (*domain.Product, error) {
	return r.getProduct(ctx, r.pool, "product_uuid = $1", uuid)
}

// GetBySKU retrieves a product by its SKU.
func (r *ProductRepository) GetBySKU(ctx context.Context, sku string) (*domain.Product, error) {
	return r.getProduct(ctx, r.pool, "sku = $1", sku)
}

func (r *ProductRepository) getProduct(ctx context.Context, q querier, where string, args ...interface{}) (*domain.Product, error) {
	query := fmt.Sprintf(`
		SELECT 
			product_id, product_uuid, sku, title, description,
			store_id, owner_org_id, main_price, strikethrough_price,
			cost_price, tax_rate, stock_left, minimum_order_quantity, net_content,
			content_unit, reference_price, reference_unit,
			logistics_length, logistics_width, logistics_height, logistics_weight, logistics_volume,
			shelf_code, is_active, is_featured, is_mini_app_recommendation,
			is_archived, product_type, parent_id, visibility,
			is_default_variant, price_min, price_max,
			stock_total, variant_options_index, etw_store_type,
			etw_mini_app_type, created_at, updated_at
		FROM admin_product WHERE %s`, where)

	product := &domain.Product{}
	var variantOptionsJSON []byte

	err := q.QueryRow(ctx, query, args...).Scan(
		&product.ProductID, &product.ProductUUID, &product.SKU, &product.Title, &product.Description,
		&product.StoreID, &product.OwnerOrgID, &product.MainPrice, &product.StrikethroughPrice,
		&product.CostPrice, &product.TaxRate, &product.StockLeft, &product.MinimumOrderQuantity, &product.NetContent,
		&product.ContentUnit, &product.ReferencePrice, &product.ReferenceUnit,
		&product.LogisticsLength, &product.LogisticsWidth, &product.LogisticsHeight, &product.LogisticsWeight, &product.LogisticsVolume,
		&product.ShelfCode, &product.IsActive, &product.IsFeatured, &product.IsMiniAppRecommendation,
		&product.IsArchived, &product.ProductType, &product.ParentID, &product.Visibility,
		&product.IsDefaultVariant, &product.PriceMin, &product.PriceMax,
		&product.StockTotal, &variantOptionsJSON, &product.ETWStoreType,
		&product.ETWMiniAppType, &product.CreatedAt, &product.UpdatedAt,
	)

	if err == pgx.ErrNoRows {
		return nil, domain.ErrProductNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get product: %w", err)
	}

	if len(variantOptionsJSON) > 0 {
		if err := json.Unmarshal(variantOptionsJSON, &product.VariantOptionsIndex); err != nil {
			return nil, fmt.Errorf("failed to unmarshal variant options: %w", err)
		}
	}

	return product, nil
}

// GetWithRelations retrieves a product with all related data.
func (r *ProductRepository) GetWithRelations(ctx context.Context, id int32) (*domain.ProductWithRelations, error) {
	product, err := r.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	result := &domain.ProductWithRelations{Product: *product}

	// Get attributes
	attrsQuery := `SELECT attribute_id, product_id, attribute_name, attribute_value, display_order, created_at
		FROM admin_product_attributes WHERE product_id = $1 ORDER BY display_order`
	rows, err := r.pool.Query(ctx, attrsQuery, id)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var attr domain.ProductAttribute
			if err := rows.Scan(&attr.AttributeID, &attr.ProductID, &attr.AttributeName, &attr.AttributeValue, &attr.DisplayOrder, &attr.CreatedAt); err == nil {
				result.Attributes = append(result.Attributes, attr)
			}
		}
	}

	// Get specifications
	specsQuery := `SELECT specification_id, product_id, spec_name, spec_value, display_order, created_at
		FROM admin_product_specifications WHERE product_id = $1 ORDER BY display_order`
	specRows, err := r.pool.Query(ctx, specsQuery, id)
	if err == nil {
		defer specRows.Close()
		for specRows.Next() {
			var spec domain.ProductSpecification
			if err := specRows.Scan(&spec.SpecificationID, &spec.ProductID, &spec.SpecName, &spec.SpecValue, &spec.DisplayOrder, &spec.CreatedAt); err == nil {
				result.Specifications = append(result.Specifications, spec)
			}
		}
	}

	// Get images
	imgsQuery := `SELECT image_id, product_id, image_url, display_order, is_primary, created_at
		FROM admin_product_images WHERE product_id = $1 ORDER BY display_order`
	imgRows, err := r.pool.Query(ctx, imgsQuery, id)
	if err == nil {
		defer imgRows.Close()
		for imgRows.Next() {
			var img domain.ProductImage
			if err := imgRows.Scan(&img.ImageID, &img.ProductID, &img.ImageURL, &img.DisplayOrder, &img.IsPrimary, &img.CreatedAt); err == nil {
				result.Images = append(result.Images, img)
			}
		}
	}

	// Get categories
	catsQuery := `SELECT c.category_id, c.name, c.image_url, c.display_order, c.is_active, c.store_id, c.etw_store_type, c.etw_mini_app_type, c.created_at, c.updated_at
		FROM admin_product_categories c
		JOIN admin_product_category_mapping m ON c.category_id = m.category_id
		WHERE m.product_id = $1`
	catRows, err := r.pool.Query(ctx, catsQuery, id)
	if err == nil {
		defer catRows.Close()
		for catRows.Next() {
			var cat domain.Category
			if err := catRows.Scan(&cat.CategoryID, &cat.Name, &cat.ImageURL, &cat.DisplayOrder, &cat.IsActive, &cat.StoreID, &cat.ETWStoreType, &cat.ETWMiniAppType, &cat.CreatedAt, &cat.UpdatedAt); err == nil {
				result.Categories = append(result.Categories, cat)
			}
		}
	}

	// Get children if parent
	if product.IsParent() {
		children, err := r.GetChildrenByParentID(ctx, id)
		if err == nil {
			result.Children = children
		}
	}

	return result, nil
}

// List retrieves products with filtering and pagination.
func (r *ProductRepository) List(ctx context.Context, filter *domain.ProductFilter, pagination repository.Pagination, sort *domain.ProductSort) (*repository.PaginatedResult[domain.Product], error) {
	var conditions []string
	var args []interface{}
	argIdx := 1

	if filter != nil {
		if filter.StoreID != nil {
			conditions = append(conditions, fmt.Sprintf("p.store_id = $%d", argIdx))
			args = append(args, *filter.StoreID)
			argIdx++
		}
		if filter.ProductType != nil {
			conditions = append(conditions, fmt.Sprintf("p.product_type = $%d", argIdx))
			args = append(args, *filter.ProductType)
			argIdx++
		}
		if filter.Visibility != nil {
			conditions = append(conditions, fmt.Sprintf("p.visibility = $%d", argIdx))
			args = append(args, *filter.Visibility)
			argIdx++
		}
		if filter.IsActive != nil {
			conditions = append(conditions, fmt.Sprintf("p.is_active = $%d", argIdx))
			args = append(args, *filter.IsActive)
			argIdx++
		}
		if filter.IsArchived != nil {
			conditions = append(conditions, fmt.Sprintf("p.is_archived = $%d", argIdx))
			args = append(args, *filter.IsArchived)
			argIdx++
		}
		if filter.ParentID != nil {
			conditions = append(conditions, fmt.Sprintf("p.parent_id = $%d", argIdx))
			args = append(args, *filter.ParentID)
			argIdx++
		}
		if filter.Search != nil && *filter.Search != "" {
			conditions = append(conditions, fmt.Sprintf("(p.title ILIKE $%d OR p.sku ILIKE $%d OR p.description ILIKE $%d)", argIdx, argIdx, argIdx))
			args = append(args, "%"+*filter.Search+"%")
			argIdx++
		}
		if filter.ETWStoreType != nil && *filter.ETWStoreType != "" {
			conditions = append(conditions, fmt.Sprintf("p.etw_store_type = $%d", argIdx))
			args = append(args, *filter.ETWStoreType)
			argIdx++
		}
		if filter.ETWMiniAppType != nil && *filter.ETWMiniAppType != "" {
			conditions = append(conditions, fmt.Sprintf("p.etw_mini_app_type = $%d", argIdx))
			args = append(args, *filter.ETWMiniAppType)
			argIdx++
		}
		if filter.IsFeatured != nil {
			conditions = append(conditions, fmt.Sprintf("p.is_featured = $%d", argIdx))
			args = append(args, *filter.IsFeatured)
			argIdx++
		}
		if filter.OwnerOrgID != nil && *filter.OwnerOrgID != "" {
			conditions = append(conditions, fmt.Sprintf("p.owner_org_id = $%d", argIdx))
			args = append(args, *filter.OwnerOrgID)
			argIdx++
		}
		if filter.CategoryID != nil {
			conditions = append(conditions, fmt.Sprintf("p.product_id IN (SELECT pcm.product_id FROM admin_product_category_mapping pcm WHERE pcm.category_id = $%d)", argIdx))
			args = append(args, *filter.CategoryID)
			argIdx++
		}
		if filter.SubcategoryID != nil {
			conditions = append(conditions, fmt.Sprintf("p.product_id IN (SELECT psm.product_id FROM admin_product_subcategory_mapping psm WHERE psm.subcategory_id = $%d)", argIdx))
			args = append(args, *filter.SubcategoryID)
			argIdx++
		}
		if filter.CollectionID != nil {
			conditions = append(conditions, fmt.Sprintf("p.product_id IN (SELECT pcm2.product_id FROM admin_product_collection_mapping pcm2 WHERE pcm2.collection_id = $%d)", argIdx))
			args = append(args, *filter.CollectionID)
			argIdx++
		}
		if filter.MinPrice != nil {
			conditions = append(conditions, fmt.Sprintf("p.main_price >= $%d", argIdx))
			args = append(args, *filter.MinPrice)
			argIdx++
		}
		if filter.MaxPrice != nil {
			conditions = append(conditions, fmt.Sprintf("p.main_price <= $%d", argIdx))
			args = append(args, *filter.MaxPrice)
			argIdx++
		}
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Count query
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM admin_product p %s", whereClause)
	var totalCount int64
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&totalCount); err != nil {
		return nil, fmt.Errorf("failed to count products: %w", err)
	}

	// Sort
	orderBy := "p.created_at DESC"
	if sort != nil {
		orderBy = fmt.Sprintf("%s %s", sort.Field, sort.Direction)
	}

	// Paginate
	offset := (pagination.Page - 1) * pagination.PageSize
	query := fmt.Sprintf(`
		SELECT 
			p.product_id, p.product_uuid, p.sku, p.title, p.description,
			p.store_id, p.owner_org_id, p.main_price, p.strikethrough_price,
			p.cost_price, p.tax_rate, p.stock_left, p.minimum_order_quantity, p.net_content,
			p.content_unit, p.reference_price, p.reference_unit,
			p.logistics_length, p.logistics_width, p.logistics_height, p.logistics_weight, p.logistics_volume,
			p.shelf_code, p.is_active, p.is_featured, p.is_mini_app_recommendation,
			p.is_archived, p.product_type, p.parent_id, p.visibility,
			p.is_default_variant, p.price_min, p.price_max,
			p.stock_total, p.variant_options_index, p.etw_store_type,
			p.etw_mini_app_type, p.created_at, p.updated_at,
			(SELECT img.image_url FROM admin_product_images img 
			 WHERE img.product_id = p.product_id AND img.is_primary = true 
			 LIMIT 1) as primary_image_url
		FROM admin_product p %s
		ORDER BY %s
		LIMIT $%d OFFSET $%d`, whereClause, orderBy, argIdx, argIdx+1)

	args = append(args, pagination.PageSize, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list products: %w", err)
	}
	defer rows.Close()

	var products []domain.Product
	for rows.Next() {
		var p domain.Product
		var variantOptionsJSON []byte

		if err := rows.Scan(
			&p.ProductID, &p.ProductUUID, &p.SKU, &p.Title, &p.Description,
			&p.StoreID, &p.OwnerOrgID, &p.MainPrice, &p.StrikethroughPrice,
			&p.CostPrice, &p.TaxRate, &p.StockLeft, &p.MinimumOrderQuantity, &p.NetContent,
			&p.ContentUnit, &p.ReferencePrice, &p.ReferenceUnit,
			&p.LogisticsLength, &p.LogisticsWidth, &p.LogisticsHeight, &p.LogisticsWeight, &p.LogisticsVolume,
			&p.ShelfCode, &p.IsActive, &p.IsFeatured, &p.IsMiniAppRecommendation,
			&p.IsArchived, &p.ProductType, &p.ParentID, &p.Visibility,
			&p.IsDefaultVariant, &p.PriceMin, &p.PriceMax,
			&p.StockTotal, &variantOptionsJSON, &p.ETWStoreType,
			&p.ETWMiniAppType, &p.CreatedAt, &p.UpdatedAt, &p.PrimaryImageURL,
		); err != nil {
			return nil, fmt.Errorf("failed to scan product: %w", err)
		}

		if len(variantOptionsJSON) > 0 {
			json.Unmarshal(variantOptionsJSON, &p.VariantOptionsIndex)
		}
		products = append(products, p)
	}

	totalPages := int(totalCount) / pagination.PageSize
	if int(totalCount)%pagination.PageSize > 0 {
		totalPages++
	}

	return &repository.PaginatedResult[domain.Product]{
		Items:      products,
		TotalCount: totalCount,
		Page:       pagination.Page,
		PageSize:   pagination.PageSize,
		TotalPages: totalPages,
	}, nil
}

// Update updates a product.
func (r *ProductRepository) Update(ctx context.Context, id int32, params *domain.UpdateProductParams) error {
	return r.updateProduct(ctx, r.pool, id, params)
}

// UpdateTx updates a product within a transaction.
func (r *ProductRepository) UpdateTx(ctx context.Context, tx pgx.Tx, id int32, params *domain.UpdateProductParams) error {
	return r.updateProduct(ctx, tx, id, params)
}

func (r *ProductRepository) updateProduct(ctx context.Context, q querier, id int32, params *domain.UpdateProductParams) error {
	var sets []string
	var args []interface{}
	argIdx := 1

	if params.SKU != nil {
		sets = append(sets, fmt.Sprintf("sku = $%d", argIdx))
		args = append(args, *params.SKU)
		argIdx++
	}
	if params.Title != nil {
		sets = append(sets, fmt.Sprintf("title = $%d", argIdx))
		args = append(args, *params.Title)
		argIdx++
	}
	if params.Description != nil {
		sets = append(sets, fmt.Sprintf("description = $%d", argIdx))
		args = append(args, *params.Description)
		argIdx++
	}
	if params.MainPrice != nil {
		sets = append(sets, fmt.Sprintf("main_price = $%d", argIdx))
		args = append(args, *params.MainPrice)
		argIdx++
	}
	if params.TaxRate != nil {
		sets = append(sets, fmt.Sprintf("tax_rate = $%d", argIdx))
		args = append(args, *params.TaxRate)
		argIdx++
	}
	if params.StockLeft != nil {
		sets = append(sets, fmt.Sprintf("stock_left = $%d", argIdx))
		args = append(args, *params.StockLeft)
		argIdx++
	}
	if params.NetContent != nil {
		sets = append(sets, fmt.Sprintf("net_content = $%d", argIdx))
		args = append(args, *params.NetContent)
		argIdx++
	}
	if params.ContentUnit != nil {
		sets = append(sets, fmt.Sprintf("content_unit = $%d", argIdx))
		args = append(args, *params.ContentUnit)
		argIdx++
	}
	if params.LogisticsLength != nil {
		sets = append(sets, fmt.Sprintf("logistics_length = $%d", argIdx))
		args = append(args, *params.LogisticsLength)
		argIdx++
	}
	if params.LogisticsWidth != nil {
		sets = append(sets, fmt.Sprintf("logistics_width = $%d", argIdx))
		args = append(args, *params.LogisticsWidth)
		argIdx++
	}
	if params.LogisticsHeight != nil {
		sets = append(sets, fmt.Sprintf("logistics_height = $%d", argIdx))
		args = append(args, *params.LogisticsHeight)
		argIdx++
	}
	if params.LogisticsWeight != nil {
		sets = append(sets, fmt.Sprintf("logistics_weight = $%d", argIdx))
		args = append(args, *params.LogisticsWeight)
		argIdx++
	}
	if params.LogisticsVolume != nil {
		sets = append(sets, fmt.Sprintf("logistics_volume = $%d", argIdx))
		args = append(args, *params.LogisticsVolume)
		argIdx++
	}
	if params.ReferencePrice != nil {
		sets = append(sets, fmt.Sprintf("reference_price = $%d", argIdx))
		args = append(args, *params.ReferencePrice)
		argIdx++
	}
	if params.ReferenceUnit != nil {
		sets = append(sets, fmt.Sprintf("reference_unit = $%d", argIdx))
		args = append(args, *params.ReferenceUnit)
		argIdx++
	}
	if params.IsActive != nil {
		sets = append(sets, fmt.Sprintf("is_active = $%d", argIdx))
		args = append(args, *params.IsActive)
		argIdx++
	}
	if params.IsArchived != nil {
		sets = append(sets, fmt.Sprintf("is_archived = $%d", argIdx))
		args = append(args, *params.IsArchived)
		argIdx++
	}
	if params.Visibility != nil {
		sets = append(sets, fmt.Sprintf("visibility = $%d", argIdx))
		args = append(args, *params.Visibility)
		argIdx++
	}
	if params.IsDefaultVariant != nil {
		sets = append(sets, fmt.Sprintf("is_default_variant = $%d", argIdx))
		args = append(args, *params.IsDefaultVariant)
		argIdx++
	}

	if len(sets) == 0 {
		return nil
	}

	sets = append(sets, "updated_at = NOW()")
	args = append(args, id)

	query := fmt.Sprintf("UPDATE admin_product SET %s WHERE product_id = $%d", strings.Join(sets, ", "), argIdx)
	_, err := q.Exec(ctx, query, args...)
	return err
}

// Delete hard-deletes a product.
func (r *ProductRepository) Delete(ctx context.Context, id int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_product WHERE product_id = $1", id)
	return err
}

// Archive soft-deletes a product.
func (r *ProductRepository) Archive(ctx context.Context, id int32) error {
	return r.archiveProduct(ctx, r.pool, id)
}

// ArchiveTx soft-deletes a product within a transaction.
func (r *ProductRepository) ArchiveTx(ctx context.Context, tx pgx.Tx, id int32) error {
	return r.archiveProduct(ctx, tx, id)
}

func (r *ProductRepository) archiveProduct(ctx context.Context, q querier, id int32) error {
	_, err := q.Exec(ctx, "UPDATE admin_product SET is_archived = true, updated_at = NOW() WHERE product_id = $1", id)
	return err
}

// GetChildrenByParentID retrieves all child products for a parent.
func (r *ProductRepository) GetChildrenByParentID(ctx context.Context, parentID int32) ([]domain.Product, error) {
	return r.getChildrenByParentID(ctx, r.pool, parentID)
}

// GetChildrenByParentIDTx retrieves all child products for a parent within a transaction.
func (r *ProductRepository) GetChildrenByParentIDTx(ctx context.Context, tx pgx.Tx, parentID int32) ([]domain.Product, error) {
	return r.getChildrenByParentID(ctx, tx, parentID)
}

func (r *ProductRepository) getChildrenByParentID(ctx context.Context, q querier, parentID int32) ([]domain.Product, error) {
	query := `
		SELECT 
			product_id, product_uuid, sku, title, description,
			store_id, owner_org_id, main_price, strikethrough_price,
			cost_price, tax_rate, stock_left, minimum_order_quantity, net_content,
			content_unit, reference_price, reference_unit,
			logistics_length, logistics_width, logistics_height, logistics_weight, logistics_volume,
			shelf_code, is_active, is_featured, is_mini_app_recommendation,
			is_archived, product_type, parent_id, visibility,
			is_default_variant, price_min, price_max,
			stock_total, variant_options_index, etw_store_type,
			etw_mini_app_type, created_at, updated_at
		FROM admin_product WHERE parent_id = $1 ORDER BY display_order, created_at`

	rows, err := q.Query(ctx, query, parentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var children []domain.Product
	for rows.Next() {
		var p domain.Product
		var variantOptionsJSON []byte

		if err := rows.Scan(
			&p.ProductID, &p.ProductUUID, &p.SKU, &p.Title, &p.Description,
			&p.StoreID, &p.OwnerOrgID, &p.MainPrice, &p.StrikethroughPrice,
			&p.CostPrice, &p.TaxRate, &p.StockLeft, &p.MinimumOrderQuantity, &p.NetContent,
			&p.ContentUnit, &p.ReferencePrice, &p.ReferenceUnit,
			&p.LogisticsLength, &p.LogisticsWidth, &p.LogisticsHeight, &p.LogisticsWeight, &p.LogisticsVolume,
			&p.ShelfCode, &p.IsActive, &p.IsFeatured, &p.IsMiniAppRecommendation,
			&p.IsArchived, &p.ProductType, &p.ParentID, &p.Visibility,
			&p.IsDefaultVariant, &p.PriceMin, &p.PriceMax,
			&p.StockTotal, &variantOptionsJSON, &p.ETWStoreType,
			&p.ETWMiniAppType, &p.CreatedAt, &p.UpdatedAt,
		); err != nil {
			return nil, err
		}

		if len(variantOptionsJSON) > 0 {
			json.Unmarshal(variantOptionsJSON, &p.VariantOptionsIndex)
		}
		children = append(children, p)
	}

	return children, nil
}

// UpdateParentAggregates updates the aggregated fields on a parent product.
func (r *ProductRepository) UpdateParentAggregates(ctx context.Context, parentID int32, params *domain.UpdateParentAggregatesParams) error {
	return r.updateParentAggregates(ctx, r.pool, parentID, params)
}

// UpdateParentAggregatesTx updates the aggregated fields on a parent product within a transaction.
func (r *ProductRepository) UpdateParentAggregatesTx(ctx context.Context, tx pgx.Tx, parentID int32, params *domain.UpdateParentAggregatesParams) error {
	return r.updateParentAggregates(ctx, tx, parentID, params)
}

func (r *ProductRepository) updateParentAggregates(ctx context.Context, q querier, parentID int32, params *domain.UpdateParentAggregatesParams) error {
	variantOptionsJSON, err := json.Marshal(params.VariantOptionsIndex)
	if err != nil {
		return fmt.Errorf("failed to marshal variant options: %w", err)
	}

	query := `
		UPDATE admin_product SET 
			price_min = $1,
			price_max = $2,
			stock_total = $3,
			variant_options_index = $4,
			updated_at = NOW()
		WHERE product_id = $5`

	_, err = q.Exec(ctx, query, params.PriceMin, params.PriceMax, params.StockTotal, variantOptionsJSON, parentID)
	return err
}

// CountByStore returns the number of products in a store.
func (r *ProductRepository) CountByStore(ctx context.Context, storeID int32) (int64, error) {
	var count int64
	err := r.pool.QueryRow(ctx, "SELECT COUNT(*) FROM admin_product WHERE store_id = $1", storeID).Scan(&count)
	return count, err
}

// SetDefaultVariant sets a child product as the default variant.
func (r *ProductRepository) SetDefaultVariant(ctx context.Context, parentID int32, childID int32) error {
	return r.setDefaultVariant(ctx, r.pool, parentID, childID)
}

// SetDefaultVariantTx sets a child product as the default variant within a transaction.
func (r *ProductRepository) SetDefaultVariantTx(ctx context.Context, tx pgx.Tx, parentID int32, childID int32) error {
	return r.setDefaultVariant(ctx, tx, parentID, childID)
}

func (r *ProductRepository) setDefaultVariant(ctx context.Context, q querier, parentID int32, childID int32) error {
	// Unset current default
	_, err := q.Exec(ctx, "UPDATE admin_product SET is_default_variant = false WHERE parent_id = $1", parentID)
	if err != nil {
		return err
	}

	// Set new default
	_, err = q.Exec(ctx, "UPDATE admin_product SET is_default_variant = true WHERE product_id = $1 AND parent_id = $2", childID, parentID)
	return err
}
