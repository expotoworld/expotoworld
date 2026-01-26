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
