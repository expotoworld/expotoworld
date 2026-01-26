package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
)

// SpecificationRepository is a PostgreSQL implementation for product specifications.
type SpecificationRepository struct {
	pool *pgxpool.Pool
}

// NewSpecificationRepository creates a new PostgreSQL specification repository.
func NewSpecificationRepository(pool *pgxpool.Pool) *SpecificationRepository {
	return &SpecificationRepository{pool: pool}
}

// specQuerier abstracts pgxpool.Pool and pgx.Tx for transaction support.
type specQuerier interface {
	Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...interface{}) pgx.Row
	Exec(ctx context.Context, sql string, args ...interface{}) (pgconn.CommandTag, error)
}

// Create creates a new specification for a product.
func (r *SpecificationRepository) Create(ctx context.Context, params *domain.CreateSpecificationParams) (*domain.ProductSpecification, error) {
	return r.createWithQuerier(ctx, r.pool, params)
}

// CreateTx creates a new specification within a transaction.
func (r *SpecificationRepository) CreateTx(ctx context.Context, tx pgx.Tx, params *domain.CreateSpecificationParams) (*domain.ProductSpecification, error) {
	return r.createWithQuerier(ctx, tx, params)
}

func (r *SpecificationRepository) createWithQuerier(ctx context.Context, q specQuerier, params *domain.CreateSpecificationParams) (*domain.ProductSpecification, error) {
	query := `
		INSERT INTO admin_product_specifications (product_id, spec_name, spec_value, display_order)
		VALUES ($1, $2, $3, $4)
		RETURNING specification_id, product_id, spec_name, spec_value, display_order, created_at`

	spec := &domain.ProductSpecification{}
	err := q.QueryRow(ctx, query, params.ProductID, params.SpecName, params.SpecValue, params.DisplayOrder).Scan(
		&spec.SpecificationID, &spec.ProductID, &spec.SpecName, &spec.SpecValue, &spec.DisplayOrder, &spec.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create specification: %w", err)
	}
	return spec, nil
}

// GetByID retrieves a specification by its ID.
func (r *SpecificationRepository) GetByID(ctx context.Context, id int32) (*domain.ProductSpecification, error) {
	query := `SELECT specification_id, product_id, spec_name, spec_value, display_order, created_at
		FROM admin_product_specifications WHERE specification_id = $1`

	spec := &domain.ProductSpecification{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&spec.SpecificationID, &spec.ProductID, &spec.SpecName, &spec.SpecValue, &spec.DisplayOrder, &spec.CreatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, domain.ErrSpecificationNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get specification: %w", err)
	}
	return spec, nil
}

// GetByProductID retrieves all specifications for a product ordered by display_order.
func (r *SpecificationRepository) GetByProductID(ctx context.Context, productID int32) ([]domain.ProductSpecification, error) {
	return r.getByProductIDWithQuerier(ctx, r.pool, productID)
}

// GetByProductIDTx retrieves all specifications for a product within a transaction.
func (r *SpecificationRepository) GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.ProductSpecification, error) {
	return r.getByProductIDWithQuerier(ctx, tx, productID)
}

func (r *SpecificationRepository) getByProductIDWithQuerier(ctx context.Context, q specQuerier, productID int32) ([]domain.ProductSpecification, error) {
	query := `SELECT specification_id, product_id, spec_name, spec_value, display_order, created_at
		FROM admin_product_specifications WHERE product_id = $1 ORDER BY display_order`

	rows, err := q.Query(ctx, query, productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var specs []domain.ProductSpecification
	for rows.Next() {
		var spec domain.ProductSpecification
		if err := rows.Scan(&spec.SpecificationID, &spec.ProductID, &spec.SpecName, &spec.SpecValue, &spec.DisplayOrder, &spec.CreatedAt); err != nil {
			return nil, err
		}
		specs = append(specs, spec)
	}
	return specs, nil
}

// Update updates a specification.
func (r *SpecificationRepository) Update(ctx context.Context, id int32, params *domain.UpdateSpecificationParams) error {
	return r.updateWithQuerier(ctx, r.pool, id, params)
}

// UpdateTx updates a specification within a transaction.
func (r *SpecificationRepository) UpdateTx(ctx context.Context, tx pgx.Tx, id int32, params *domain.UpdateSpecificationParams) error {
	return r.updateWithQuerier(ctx, tx, id, params)
}

func (r *SpecificationRepository) updateWithQuerier(ctx context.Context, q specQuerier, id int32, params *domain.UpdateSpecificationParams) error {
	query := `UPDATE admin_product_specifications SET spec_name = $1, spec_value = $2, display_order = $3 WHERE specification_id = $4`
	_, err := q.Exec(ctx, query, params.SpecName, params.SpecValue, params.DisplayOrder, id)
	return err
}

// Delete deletes a specification.
func (r *SpecificationRepository) Delete(ctx context.Context, id int32) error {
	return r.deleteWithQuerier(ctx, r.pool, id)
}

// DeleteTx deletes a specification within a transaction.
func (r *SpecificationRepository) DeleteTx(ctx context.Context, tx pgx.Tx, id int32) error {
	return r.deleteWithQuerier(ctx, tx, id)
}

func (r *SpecificationRepository) deleteWithQuerier(ctx context.Context, q specQuerier, id int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_specifications WHERE specification_id = $1", id)
	return err
}

// DeleteByProductID deletes all specifications for a product.
func (r *SpecificationRepository) DeleteByProductID(ctx context.Context, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, r.pool, productID)
}

// DeleteByProductIDTx deletes all specifications for a product within a transaction.
func (r *SpecificationRepository) DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, tx, productID)
}

func (r *SpecificationRepository) deleteByProductIDWithQuerier(ctx context.Context, q specQuerier, productID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_specifications WHERE product_id = $1", productID)
	return err
}

// BulkCreate creates multiple specifications in a single operation.
func (r *SpecificationRepository) BulkCreate(ctx context.Context, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error) {
	return r.bulkCreateWithQuerier(ctx, r.pool, productID, specs)
}

// BulkCreateTx creates multiple specifications within a transaction.
func (r *SpecificationRepository) BulkCreateTx(ctx context.Context, tx pgx.Tx, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error) {
	return r.bulkCreateWithQuerier(ctx, tx, productID, specs)
}

func (r *SpecificationRepository) bulkCreateWithQuerier(ctx context.Context, q specQuerier, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error) {
	var result []domain.ProductSpecification

	for _, params := range specs {
		params.ProductID = productID
		spec, err := r.createWithQuerier(ctx, q, &params)
		if err != nil {
			return nil, err
		}
		result = append(result, *spec)
	}

	return result, nil
}

// ReplaceAll deletes all existing specifications and creates new ones.
func (r *SpecificationRepository) ReplaceAll(ctx context.Context, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Delete existing
	if err := r.deleteByProductIDWithQuerier(ctx, tx, productID); err != nil {
		return nil, err
	}

	// Create new
	result, err := r.bulkCreateWithQuerier(ctx, tx, productID, specs)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return result, nil
}

// ReplaceAllTx replaces all specifications within a transaction.
func (r *SpecificationRepository) ReplaceAllTx(ctx context.Context, tx pgx.Tx, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error) {
	// Delete existing
	if err := r.deleteByProductIDWithQuerier(ctx, tx, productID); err != nil {
		return nil, err
	}

	// Create new
	return r.bulkCreateWithQuerier(ctx, tx, productID, specs)
}

// CopyFromProduct copies all specifications from a source product to a target product.
// Used when generating child variants to inherit parent specifications.
func (r *SpecificationRepository) CopyFromProduct(ctx context.Context, sourceProductID, targetProductID int32) ([]domain.ProductSpecification, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	result, err := r.CopyFromProductTx(ctx, tx, sourceProductID, targetProductID)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return result, nil
}

// CopyFromProductTx copies specifications within a transaction.
func (r *SpecificationRepository) CopyFromProductTx(ctx context.Context, tx pgx.Tx, sourceProductID, targetProductID int32) ([]domain.ProductSpecification, error) {
	// Get source specs
	sourceSpecs, err := r.getByProductIDWithQuerier(ctx, tx, sourceProductID)
	if err != nil {
		return nil, fmt.Errorf("failed to get source specifications: %w", err)
	}

	if len(sourceSpecs) == 0 {
		return []domain.ProductSpecification{}, nil
	}

	// Convert to create params
	createParams := make([]domain.CreateSpecificationParams, len(sourceSpecs))
	for i, spec := range sourceSpecs {
		createParams[i] = domain.CreateSpecificationParams{
			ProductID:    targetProductID,
			SpecName:     spec.SpecName,
			SpecValue:    spec.SpecValue,
			DisplayOrder: spec.DisplayOrder,
		}
	}

	// Bulk create
	return r.bulkCreateWithQuerier(ctx, tx, targetProductID, createParams)
}
