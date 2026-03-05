package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
)

// CategoryMappingRepository is a PostgreSQL implementation of CategoryMappingRepository.
type CategoryMappingRepository struct {
	pool *pgxpool.Pool
}

// NewCategoryMappingRepository creates a new PostgreSQL category mapping repository.
func NewCategoryMappingRepository(pool *pgxpool.Pool) *CategoryMappingRepository {
	return &CategoryMappingRepository{pool: pool}
}

// mappingQuerier abstracts pgxpool.Pool and pgx.Tx for transaction support.
type mappingQuerier interface {
	Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...interface{}) pgx.Row
	Exec(ctx context.Context, sql string, args ...interface{}) (pgconn.CommandTag, error)
}

// Create creates a new category mapping.
func (r *CategoryMappingRepository) Create(ctx context.Context, productID int32, categoryID int32) (*domain.CategoryMapping, error) {
	return r.createWithQuerier(ctx, r.pool, productID, categoryID)
}

// CreateTx creates a new category mapping within a transaction.
func (r *CategoryMappingRepository) CreateTx(ctx context.Context, tx pgx.Tx, productID int32, categoryID int32) (*domain.CategoryMapping, error) {
	return r.createWithQuerier(ctx, tx, productID, categoryID)
}

func (r *CategoryMappingRepository) createWithQuerier(ctx context.Context, q mappingQuerier, productID int32, categoryID int32) (*domain.CategoryMapping, error) {
	query := `
		INSERT INTO admin_product_category_mapping (product_id, category_id)
		VALUES ($1, $2)
		ON CONFLICT (product_id, category_id) DO NOTHING`

	_, err := q.Exec(ctx, query, productID, categoryID)
	if err != nil {
		return nil, fmt.Errorf("failed to create category mapping: %w", err)
	}
	return &domain.CategoryMapping{
		ProductID:  productID,
		CategoryID: categoryID,
	}, nil
}

// GetByProductID retrieves all category mappings for a product.
func (r *CategoryMappingRepository) GetByProductID(ctx context.Context, productID int32) ([]domain.CategoryMapping, error) {
	return r.getByProductIDWithQuerier(ctx, r.pool, productID)
}

// GetByProductIDTx retrieves all category mappings for a product within a transaction.
func (r *CategoryMappingRepository) GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.CategoryMapping, error) {
	return r.getByProductIDWithQuerier(ctx, tx, productID)
}

func (r *CategoryMappingRepository) getByProductIDWithQuerier(ctx context.Context, q mappingQuerier, productID int32) ([]domain.CategoryMapping, error) {
	query := `SELECT product_id, category_id FROM admin_product_category_mapping WHERE product_id = $1`

	rows, err := q.Query(ctx, query, productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mappings []domain.CategoryMapping
	for rows.Next() {
		var m domain.CategoryMapping
		if err := rows.Scan(&m.ProductID, &m.CategoryID); err != nil {
			return nil, err
		}
		mappings = append(mappings, m)
	}
	return mappings, nil
}

// GetByCategoryID retrieves all category mappings for a category.
func (r *CategoryMappingRepository) GetByCategoryID(ctx context.Context, categoryID int32) ([]domain.CategoryMapping, error) {
	query := `SELECT product_id, category_id FROM admin_product_category_mapping WHERE category_id = $1`

	rows, err := r.pool.Query(ctx, query, categoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mappings []domain.CategoryMapping
	for rows.Next() {
		var m domain.CategoryMapping
		if err := rows.Scan(&m.ProductID, &m.CategoryID); err != nil {
			return nil, err
		}
		mappings = append(mappings, m)
	}
	return mappings, nil
}

// Delete deletes a category mapping.
func (r *CategoryMappingRepository) Delete(ctx context.Context, productID int32, categoryID int32) error {
	return r.deleteWithQuerier(ctx, r.pool, productID, categoryID)
}

// DeleteTx deletes a category mapping within a transaction.
func (r *CategoryMappingRepository) DeleteTx(ctx context.Context, tx pgx.Tx, productID int32, categoryID int32) error {
	return r.deleteWithQuerier(ctx, tx, productID, categoryID)
}

func (r *CategoryMappingRepository) deleteWithQuerier(ctx context.Context, q mappingQuerier, productID int32, categoryID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_category_mapping WHERE product_id = $1 AND category_id = $2", productID, categoryID)
	return err
}

// DeleteByProductID deletes all category mappings for a product.
func (r *CategoryMappingRepository) DeleteByProductID(ctx context.Context, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, r.pool, productID)
}

// DeleteByProductIDTx deletes all category mappings for a product within a transaction.
func (r *CategoryMappingRepository) DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, tx, productID)
}

func (r *CategoryMappingRepository) deleteByProductIDWithQuerier(ctx context.Context, q mappingQuerier, productID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_category_mapping WHERE product_id = $1", productID)
	return err
}

// DeleteByCategoryID deletes all mappings for a category.
func (r *CategoryMappingRepository) DeleteByCategoryID(ctx context.Context, categoryID int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_product_category_mapping WHERE category_id = $1", categoryID)
	return err
}

// SetCategories replaces all categories for a product with the new list.
func (r *CategoryMappingRepository) SetCategories(ctx context.Context, productID int32, categoryIDs []int32) error {
	return r.setCategoriesWithQuerier(ctx, r.pool, productID, categoryIDs)
}

// SetCategoriesTx replaces all categories within a transaction.
func (r *CategoryMappingRepository) SetCategoriesTx(ctx context.Context, tx pgx.Tx, productID int32, categoryIDs []int32) error {
	return r.setCategoriesWithQuerier(ctx, tx, productID, categoryIDs)
}

func (r *CategoryMappingRepository) setCategoriesWithQuerier(ctx context.Context, q mappingQuerier, productID int32, categoryIDs []int32) error {
	// Delete all existing mappings
	if err := r.deleteByProductIDWithQuerier(ctx, q, productID); err != nil {
		return err
	}

	// Create new mappings
	for _, categoryID := range categoryIDs {
		_, err := r.createWithQuerier(ctx, q, productID, categoryID)
		if err != nil {
			return err
		}
	}
	return nil
}

// ============================================================================
// SubcategoryMappingRepository
// ============================================================================

// SubcategoryMappingRepository is a PostgreSQL implementation of SubcategoryMappingRepository.
type SubcategoryMappingRepository struct {
	pool *pgxpool.Pool
}

// NewSubcategoryMappingRepository creates a new PostgreSQL subcategory mapping repository.
func NewSubcategoryMappingRepository(pool *pgxpool.Pool) *SubcategoryMappingRepository {
	return &SubcategoryMappingRepository{pool: pool}
}

// Create creates a new subcategory mapping.
func (r *SubcategoryMappingRepository) Create(ctx context.Context, productID int32, subcategoryID int32) (*domain.SubcategoryMapping, error) {
	return r.createWithQuerier(ctx, r.pool, productID, subcategoryID)
}

// CreateTx creates a new subcategory mapping within a transaction.
func (r *SubcategoryMappingRepository) CreateTx(ctx context.Context, tx pgx.Tx, productID int32, subcategoryID int32) (*domain.SubcategoryMapping, error) {
	return r.createWithQuerier(ctx, tx, productID, subcategoryID)
}

func (r *SubcategoryMappingRepository) createWithQuerier(ctx context.Context, q mappingQuerier, productID int32, subcategoryID int32) (*domain.SubcategoryMapping, error) {
	query := `
		INSERT INTO admin_product_subcategory_mapping (product_id, subcategory_id)
		VALUES ($1, $2)
		ON CONFLICT (product_id, subcategory_id) DO NOTHING`

	_, err := q.Exec(ctx, query, productID, subcategoryID)
	if err != nil {
		return nil, fmt.Errorf("failed to create subcategory mapping: %w", err)
	}
	return &domain.SubcategoryMapping{
		ProductID:     productID,
		SubcategoryID: subcategoryID,
	}, nil
}

// GetByProductID retrieves all subcategory mappings for a product.
func (r *SubcategoryMappingRepository) GetByProductID(ctx context.Context, productID int32) ([]domain.SubcategoryMapping, error) {
	return r.getByProductIDWithQuerier(ctx, r.pool, productID)
}

// GetByProductIDTx retrieves all subcategory mappings for a product within a transaction.
func (r *SubcategoryMappingRepository) GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.SubcategoryMapping, error) {
	return r.getByProductIDWithQuerier(ctx, tx, productID)
}

func (r *SubcategoryMappingRepository) getByProductIDWithQuerier(ctx context.Context, q mappingQuerier, productID int32) ([]domain.SubcategoryMapping, error) {
	query := `SELECT product_id, subcategory_id FROM admin_product_subcategory_mapping WHERE product_id = $1`

	rows, err := q.Query(ctx, query, productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mappings []domain.SubcategoryMapping
	for rows.Next() {
		var m domain.SubcategoryMapping
		if err := rows.Scan(&m.ProductID, &m.SubcategoryID); err != nil {
			return nil, err
		}
		mappings = append(mappings, m)
	}
	return mappings, nil
}

// GetBySubcategoryID retrieves all subcategory mappings for a subcategory.
func (r *SubcategoryMappingRepository) GetBySubcategoryID(ctx context.Context, subcategoryID int32) ([]domain.SubcategoryMapping, error) {
	query := `SELECT product_id, subcategory_id FROM admin_product_subcategory_mapping WHERE subcategory_id = $1`

	rows, err := r.pool.Query(ctx, query, subcategoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mappings []domain.SubcategoryMapping
	for rows.Next() {
		var m domain.SubcategoryMapping
		if err := rows.Scan(&m.ProductID, &m.SubcategoryID); err != nil {
			return nil, err
		}
		mappings = append(mappings, m)
	}
	return mappings, nil
}

// Delete deletes a subcategory mapping.
func (r *SubcategoryMappingRepository) Delete(ctx context.Context, productID int32, subcategoryID int32) error {
	return r.deleteWithQuerier(ctx, r.pool, productID, subcategoryID)
}

// DeleteTx deletes a subcategory mapping within a transaction.
func (r *SubcategoryMappingRepository) DeleteTx(ctx context.Context, tx pgx.Tx, productID int32, subcategoryID int32) error {
	return r.deleteWithQuerier(ctx, tx, productID, subcategoryID)
}

func (r *SubcategoryMappingRepository) deleteWithQuerier(ctx context.Context, q mappingQuerier, productID int32, subcategoryID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_subcategory_mapping WHERE product_id = $1 AND subcategory_id = $2", productID, subcategoryID)
	return err
}

// DeleteByProductID deletes all subcategory mappings for a product.
func (r *SubcategoryMappingRepository) DeleteByProductID(ctx context.Context, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, r.pool, productID)
}

// DeleteByProductIDTx deletes all subcategory mappings for a product within a transaction.
func (r *SubcategoryMappingRepository) DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, tx, productID)
}

func (r *SubcategoryMappingRepository) deleteByProductIDWithQuerier(ctx context.Context, q mappingQuerier, productID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_subcategory_mapping WHERE product_id = $1", productID)
	return err
}

// DeleteBySubcategoryID deletes all mappings for a subcategory.
func (r *SubcategoryMappingRepository) DeleteBySubcategoryID(ctx context.Context, subcategoryID int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_product_subcategory_mapping WHERE subcategory_id = $1", subcategoryID)
	return err
}

// SetSubcategories replaces all subcategories for a product with the new list.
func (r *SubcategoryMappingRepository) SetSubcategories(ctx context.Context, productID int32, subcategoryIDs []int32) error {
	return r.setSubcategoriesWithQuerier(ctx, r.pool, productID, subcategoryIDs)
}

// SetSubcategoriesTx replaces all subcategories within a transaction.
func (r *SubcategoryMappingRepository) SetSubcategoriesTx(ctx context.Context, tx pgx.Tx, productID int32, subcategoryIDs []int32) error {
	return r.setSubcategoriesWithQuerier(ctx, tx, productID, subcategoryIDs)
}

func (r *SubcategoryMappingRepository) setSubcategoriesWithQuerier(ctx context.Context, q mappingQuerier, productID int32, subcategoryIDs []int32) error {
	// Delete all existing mappings
	if err := r.deleteByProductIDWithQuerier(ctx, q, productID); err != nil {
		return err
	}

	// Create new mappings
	for _, subcategoryID := range subcategoryIDs {
		_, err := r.createWithQuerier(ctx, q, productID, subcategoryID)
		if err != nil {
			return err
		}
	}
	return nil
}

// ----------------------------------------------------------------
// CollectionMappingRepository
// ----------------------------------------------------------------

// CollectionMappingRepository implements product-collection mapping data access.
type CollectionMappingRepository struct {
	pool *pgxpool.Pool
}

// NewCollectionMappingRepository creates a new collection mapping repository.
func NewCollectionMappingRepository(pool *pgxpool.Pool) *CollectionMappingRepository {
	return &CollectionMappingRepository{pool: pool}
}

// Create creates a new product-collection mapping.
func (r *CollectionMappingRepository) Create(ctx context.Context, productID int32, collectionID int32) (*domain.CollectionMapping, error) {
	return r.createWithQuerier(ctx, r.pool, productID, collectionID)
}

// CreateTx creates a new product-collection mapping within a transaction.
func (r *CollectionMappingRepository) CreateTx(ctx context.Context, tx pgx.Tx, productID int32, collectionID int32) (*domain.CollectionMapping, error) {
	return r.createWithQuerier(ctx, tx, productID, collectionID)
}

func (r *CollectionMappingRepository) createWithQuerier(ctx context.Context, q mappingQuerier, productID int32, collectionID int32) (*domain.CollectionMapping, error) {
	query := `INSERT INTO admin_product_collection_mapping (product_id, collection_id) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING product_id, collection_id`
	var m domain.CollectionMapping
	err := q.QueryRow(ctx, query, productID, collectionID).Scan(&m.ProductID, &m.CollectionID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return &domain.CollectionMapping{ProductID: productID, CollectionID: collectionID}, nil
		}
		return nil, fmt.Errorf("failed to create collection mapping: %w", err)
	}
	return &m, nil
}

// GetByProductID retrieves all collection mappings for a product.
func (r *CollectionMappingRepository) GetByProductID(ctx context.Context, productID int32) ([]domain.CollectionMapping, error) {
	return r.getByProductIDWithQuerier(ctx, r.pool, productID)
}

// GetByProductIDTx retrieves all collection mappings within a transaction.
func (r *CollectionMappingRepository) GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.CollectionMapping, error) {
	return r.getByProductIDWithQuerier(ctx, tx, productID)
}

func (r *CollectionMappingRepository) getByProductIDWithQuerier(ctx context.Context, q mappingQuerier, productID int32) ([]domain.CollectionMapping, error) {
	rows, err := q.Query(ctx, "SELECT product_id, collection_id FROM admin_product_collection_mapping WHERE product_id = $1", productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mappings []domain.CollectionMapping
	for rows.Next() {
		var m domain.CollectionMapping
		if err := rows.Scan(&m.ProductID, &m.CollectionID); err != nil {
			return nil, err
		}
		mappings = append(mappings, m)
	}
	return mappings, nil
}

// GetByCollectionID retrieves all mappings for a collection.
func (r *CollectionMappingRepository) GetByCollectionID(ctx context.Context, collectionID int32) ([]domain.CollectionMapping, error) {
	rows, err := r.pool.Query(ctx, "SELECT product_id, collection_id FROM admin_product_collection_mapping WHERE collection_id = $1", collectionID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mappings []domain.CollectionMapping
	for rows.Next() {
		var m domain.CollectionMapping
		if err := rows.Scan(&m.ProductID, &m.CollectionID); err != nil {
			return nil, err
		}
		mappings = append(mappings, m)
	}
	return mappings, nil
}

// Delete deletes a specific product-collection mapping.
func (r *CollectionMappingRepository) Delete(ctx context.Context, productID int32, collectionID int32) error {
	return r.deleteWithQuerier(ctx, r.pool, productID, collectionID)
}

// DeleteTx deletes a mapping within a transaction.
func (r *CollectionMappingRepository) DeleteTx(ctx context.Context, tx pgx.Tx, productID int32, collectionID int32) error {
	return r.deleteWithQuerier(ctx, tx, productID, collectionID)
}

func (r *CollectionMappingRepository) deleteWithQuerier(ctx context.Context, q mappingQuerier, productID int32, collectionID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_collection_mapping WHERE product_id = $1 AND collection_id = $2", productID, collectionID)
	return err
}

// DeleteByProductID deletes all collection mappings for a product.
func (r *CollectionMappingRepository) DeleteByProductID(ctx context.Context, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, r.pool, productID)
}

// DeleteByProductIDTx deletes all collection mappings within a transaction.
func (r *CollectionMappingRepository) DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, tx, productID)
}

func (r *CollectionMappingRepository) deleteByProductIDWithQuerier(ctx context.Context, q mappingQuerier, productID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_collection_mapping WHERE product_id = $1", productID)
	return err
}

// DeleteByCollectionID deletes all mappings for a collection.
func (r *CollectionMappingRepository) DeleteByCollectionID(ctx context.Context, collectionID int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_product_collection_mapping WHERE collection_id = $1", collectionID)
	return err
}

// SetCollections replaces all collections for a product with the new list.
func (r *CollectionMappingRepository) SetCollections(ctx context.Context, productID int32, collectionIDs []int32) error {
	return r.setCollectionsWithQuerier(ctx, r.pool, productID, collectionIDs)
}

// SetCollectionsTx replaces all collections within a transaction.
func (r *CollectionMappingRepository) SetCollectionsTx(ctx context.Context, tx pgx.Tx, productID int32, collectionIDs []int32) error {
	return r.setCollectionsWithQuerier(ctx, tx, productID, collectionIDs)
}

func (r *CollectionMappingRepository) setCollectionsWithQuerier(ctx context.Context, q mappingQuerier, productID int32, collectionIDs []int32) error {
	// Delete all existing mappings
	if err := r.deleteByProductIDWithQuerier(ctx, q, productID); err != nil {
		return err
	}

	// Create new mappings
	for _, collectionID := range collectionIDs {
		_, err := r.createWithQuerier(ctx, q, productID, collectionID)
		if err != nil {
			return err
		}
	}
	return nil
}

// SubcollectionMappingRepository is a PostgreSQL implementation of SubcollectionMappingRepository.
type SubcollectionMappingRepository struct {
	pool *pgxpool.Pool
}

// NewSubcollectionMappingRepository creates a new PostgreSQL subcollection mapping repository.
func NewSubcollectionMappingRepository(pool *pgxpool.Pool) *SubcollectionMappingRepository {
	return &SubcollectionMappingRepository{pool: pool}
}

// Create creates a new product-subcollection mapping.
func (r *SubcollectionMappingRepository) Create(ctx context.Context, productID int32, subcollectionID int32) (*domain.SubcollectionMapping, error) {
	return r.createWithQuerier(ctx, r.pool, productID, subcollectionID)
}

// CreateTx creates a new product-subcollection mapping within a transaction.
func (r *SubcollectionMappingRepository) CreateTx(ctx context.Context, tx pgx.Tx, productID int32, subcollectionID int32) (*domain.SubcollectionMapping, error) {
	return r.createWithQuerier(ctx, tx, productID, subcollectionID)
}

func (r *SubcollectionMappingRepository) createWithQuerier(ctx context.Context, q mappingQuerier, productID int32, subcollectionID int32) (*domain.SubcollectionMapping, error) {
	query := `INSERT INTO admin_product_subcollection_mapping (product_id, subcollection_id) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING product_id, subcollection_id`
	var m domain.SubcollectionMapping
	err := q.QueryRow(ctx, query, productID, subcollectionID).Scan(&m.ProductID, &m.SubcollectionID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return &domain.SubcollectionMapping{ProductID: productID, SubcollectionID: subcollectionID}, nil
		}
		return nil, fmt.Errorf("failed to create subcollection mapping: %w", err)
	}
	return &m, nil
}

// GetByProductID retrieves all subcollection mappings for a product.
func (r *SubcollectionMappingRepository) GetByProductID(ctx context.Context, productID int32) ([]domain.SubcollectionMapping, error) {
	return r.getByProductIDWithQuerier(ctx, r.pool, productID)
}

// GetByProductIDTx retrieves all subcollection mappings within a transaction.
func (r *SubcollectionMappingRepository) GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.SubcollectionMapping, error) {
	return r.getByProductIDWithQuerier(ctx, tx, productID)
}

func (r *SubcollectionMappingRepository) getByProductIDWithQuerier(ctx context.Context, q mappingQuerier, productID int32) ([]domain.SubcollectionMapping, error) {
	rows, err := q.Query(ctx, "SELECT product_id, subcollection_id FROM admin_product_subcollection_mapping WHERE product_id = $1", productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mappings []domain.SubcollectionMapping
	for rows.Next() {
		var m domain.SubcollectionMapping
		if err := rows.Scan(&m.ProductID, &m.SubcollectionID); err != nil {
			return nil, err
		}
		mappings = append(mappings, m)
	}
	return mappings, nil
}

// GetBySubcollectionID retrieves all mappings for a subcollection.
func (r *SubcollectionMappingRepository) GetBySubcollectionID(ctx context.Context, subcollectionID int32) ([]domain.SubcollectionMapping, error) {
	rows, err := r.pool.Query(ctx, "SELECT product_id, subcollection_id FROM admin_product_subcollection_mapping WHERE subcollection_id = $1", subcollectionID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mappings []domain.SubcollectionMapping
	for rows.Next() {
		var m domain.SubcollectionMapping
		if err := rows.Scan(&m.ProductID, &m.SubcollectionID); err != nil {
			return nil, err
		}
		mappings = append(mappings, m)
	}
	return mappings, nil
}

// Delete deletes a specific product-subcollection mapping.
func (r *SubcollectionMappingRepository) Delete(ctx context.Context, productID int32, subcollectionID int32) error {
	return r.deleteWithQuerier(ctx, r.pool, productID, subcollectionID)
}

// DeleteTx deletes a mapping within a transaction.
func (r *SubcollectionMappingRepository) DeleteTx(ctx context.Context, tx pgx.Tx, productID int32, subcollectionID int32) error {
	return r.deleteWithQuerier(ctx, tx, productID, subcollectionID)
}

func (r *SubcollectionMappingRepository) deleteWithQuerier(ctx context.Context, q mappingQuerier, productID int32, subcollectionID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_subcollection_mapping WHERE product_id = $1 AND subcollection_id = $2", productID, subcollectionID)
	return err
}

// DeleteByProductID deletes all subcollection mappings for a product.
func (r *SubcollectionMappingRepository) DeleteByProductID(ctx context.Context, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, r.pool, productID)
}

// DeleteByProductIDTx deletes all subcollection mappings within a transaction.
func (r *SubcollectionMappingRepository) DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, tx, productID)
}

func (r *SubcollectionMappingRepository) deleteByProductIDWithQuerier(ctx context.Context, q mappingQuerier, productID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_subcollection_mapping WHERE product_id = $1", productID)
	return err
}

// DeleteBySubcollectionID deletes all mappings for a subcollection.
func (r *SubcollectionMappingRepository) DeleteBySubcollectionID(ctx context.Context, subcollectionID int32) error {
	_, err := r.pool.Exec(ctx, "DELETE FROM admin_product_subcollection_mapping WHERE subcollection_id = $1", subcollectionID)
	return err
}

// SetSubcollections replaces all subcollections for a product with the new list.
func (r *SubcollectionMappingRepository) SetSubcollections(ctx context.Context, productID int32, subcollectionIDs []int32) error {
	return r.setSubcollectionsWithQuerier(ctx, r.pool, productID, subcollectionIDs)
}

// SetSubcollectionsTx replaces all subcollections within a transaction.
func (r *SubcollectionMappingRepository) SetSubcollectionsTx(ctx context.Context, tx pgx.Tx, productID int32, subcollectionIDs []int32) error {
	return r.setSubcollectionsWithQuerier(ctx, tx, productID, subcollectionIDs)
}

func (r *SubcollectionMappingRepository) setSubcollectionsWithQuerier(ctx context.Context, q mappingQuerier, productID int32, subcollectionIDs []int32) error {
	// Delete all existing mappings
	if err := r.deleteByProductIDWithQuerier(ctx, q, productID); err != nil {
		return err
	}

	// Create new mappings
	for _, subcollectionID := range subcollectionIDs {
		_, err := r.createWithQuerier(ctx, q, productID, subcollectionID)
		if err != nil {
			return err
		}
	}
	return nil
}
