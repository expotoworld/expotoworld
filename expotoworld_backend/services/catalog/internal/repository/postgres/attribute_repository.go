package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
)

// AttributeRepository is a PostgreSQL implementation of AttributeRepository.
type AttributeRepository struct {
	pool *pgxpool.Pool
}

// NewAttributeRepository creates a new PostgreSQL attribute repository.
func NewAttributeRepository(pool *pgxpool.Pool) *AttributeRepository {
	return &AttributeRepository{pool: pool}
}

// querier abstracts pgxpool.Pool and pgx.Tx for transaction support.
type attributeQuerier interface {
	Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...interface{}) pgx.Row
	Exec(ctx context.Context, sql string, args ...interface{}) (pgconn.CommandTag, error)
}

// Create creates a new attribute for a product.
func (r *AttributeRepository) Create(ctx context.Context, params *domain.CreateAttributeParams) (*domain.ProductAttribute, error) {
	return r.createWithQuerier(ctx, r.pool, params)
}

// CreateTx creates a new attribute within a transaction.
func (r *AttributeRepository) CreateTx(ctx context.Context, tx pgx.Tx, params *domain.CreateAttributeParams) (*domain.ProductAttribute, error) {
	return r.createWithQuerier(ctx, tx, params)
}

func (r *AttributeRepository) createWithQuerier(ctx context.Context, q attributeQuerier, params *domain.CreateAttributeParams) (*domain.ProductAttribute, error) {
	query := `
		INSERT INTO admin_product_attributes (product_id, attribute_name, attribute_value, display_order)
		VALUES ($1, $2, $3, $4)
		RETURNING attribute_id, product_id, attribute_name, attribute_value, display_order, created_at`

	attr := &domain.ProductAttribute{}
	err := q.QueryRow(ctx, query, params.ProductID, params.AttributeName, params.AttributeValue, params.DisplayOrder).Scan(
		&attr.AttributeID, &attr.ProductID, &attr.AttributeName, &attr.AttributeValue, &attr.DisplayOrder, &attr.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create attribute: %w", err)
	}
	return attr, nil
}

// GetByID retrieves an attribute by its ID.
func (r *AttributeRepository) GetByID(ctx context.Context, id int32) (*domain.ProductAttribute, error) {
	query := `SELECT attribute_id, product_id, attribute_name, attribute_value, display_order, created_at
		FROM admin_product_attributes WHERE attribute_id = $1`

	attr := &domain.ProductAttribute{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&attr.AttributeID, &attr.ProductID, &attr.AttributeName, &attr.AttributeValue, &attr.DisplayOrder, &attr.CreatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, domain.ErrAttributeNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get attribute: %w", err)
	}
	return attr, nil
}

// GetByProductID retrieves all attributes for a product ordered by display_order.
func (r *AttributeRepository) GetByProductID(ctx context.Context, productID int32) ([]domain.ProductAttribute, error) {
	return r.getByProductIDWithQuerier(ctx, r.pool, productID)
}

// GetByProductIDTx retrieves all attributes for a product within a transaction.
func (r *AttributeRepository) GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.ProductAttribute, error) {
	return r.getByProductIDWithQuerier(ctx, tx, productID)
}

func (r *AttributeRepository) getByProductIDWithQuerier(ctx context.Context, q attributeQuerier, productID int32) ([]domain.ProductAttribute, error) {
	query := `SELECT attribute_id, product_id, attribute_name, attribute_value, display_order, created_at
		FROM admin_product_attributes WHERE product_id = $1 ORDER BY display_order`

	rows, err := q.Query(ctx, query, productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var attributes []domain.ProductAttribute
	for rows.Next() {
		var attr domain.ProductAttribute
		if err := rows.Scan(&attr.AttributeID, &attr.ProductID, &attr.AttributeName, &attr.AttributeValue, &attr.DisplayOrder, &attr.CreatedAt); err != nil {
			return nil, err
		}
		attributes = append(attributes, attr)
	}
	return attributes, nil
}

// Update updates an attribute.
func (r *AttributeRepository) Update(ctx context.Context, id int32, params *domain.UpdateAttributeParams) error {
	return r.updateWithQuerier(ctx, r.pool, id, params)
}

// UpdateTx updates an attribute within a transaction.
func (r *AttributeRepository) UpdateTx(ctx context.Context, tx pgx.Tx, id int32, params *domain.UpdateAttributeParams) error {
	return r.updateWithQuerier(ctx, tx, id, params)
}

func (r *AttributeRepository) updateWithQuerier(ctx context.Context, q attributeQuerier, id int32, params *domain.UpdateAttributeParams) error {
	query := `UPDATE admin_product_attributes SET attribute_name = $1, attribute_value = $2, display_order = $3 WHERE attribute_id = $4`
	_, err := q.Exec(ctx, query, params.AttributeName, params.AttributeValue, params.DisplayOrder, id)
	return err
}

// Delete deletes an attribute.
func (r *AttributeRepository) Delete(ctx context.Context, id int32) error {
	return r.deleteWithQuerier(ctx, r.pool, id)
}

// DeleteTx deletes an attribute within a transaction.
func (r *AttributeRepository) DeleteTx(ctx context.Context, tx pgx.Tx, id int32) error {
	return r.deleteWithQuerier(ctx, tx, id)
}

func (r *AttributeRepository) deleteWithQuerier(ctx context.Context, q attributeQuerier, id int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_attributes WHERE attribute_id = $1", id)
	return err
}

// DeleteByProductID deletes all attributes for a product.
func (r *AttributeRepository) DeleteByProductID(ctx context.Context, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, r.pool, productID)
}

// DeleteByProductIDTx deletes all attributes for a product within a transaction.
func (r *AttributeRepository) DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, tx, productID)
}

func (r *AttributeRepository) deleteByProductIDWithQuerier(ctx context.Context, q attributeQuerier, productID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_attributes WHERE product_id = $1", productID)
	return err
}

// BulkCreate creates multiple attributes in a single operation.
func (r *AttributeRepository) BulkCreate(ctx context.Context, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error) {
	return r.bulkCreateWithQuerier(ctx, r.pool, productID, attributes)
}

// BulkCreateTx creates multiple attributes within a transaction.
func (r *AttributeRepository) BulkCreateTx(ctx context.Context, tx pgx.Tx, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error) {
	return r.bulkCreateWithQuerier(ctx, tx, productID, attributes)
}

func (r *AttributeRepository) bulkCreateWithQuerier(ctx context.Context, q attributeQuerier, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error) {
	var result []domain.ProductAttribute

	for _, params := range attributes {
		params.ProductID = productID
		attr, err := r.createWithQuerier(ctx, q, &params)
		if err != nil {
			return nil, err
		}
		result = append(result, *attr)
	}

	return result, nil
}

// ReplaceAll deletes all existing attributes and creates new ones.
func (r *AttributeRepository) ReplaceAll(ctx context.Context, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error) {
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
	result, err := r.bulkCreateWithQuerier(ctx, tx, productID, attributes)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return result, nil
}

// ReplaceAllTx replaces all attributes within a transaction.
func (r *AttributeRepository) ReplaceAllTx(ctx context.Context, tx pgx.Tx, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error) {
	// Delete existing
	if err := r.deleteByProductIDWithQuerier(ctx, tx, productID); err != nil {
		return nil, err
	}

	// Create new
	return r.bulkCreateWithQuerier(ctx, tx, productID, attributes)
}
