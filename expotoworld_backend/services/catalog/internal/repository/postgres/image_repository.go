package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
)

// ImageRepository is a PostgreSQL implementation of ImageRepository.
type ImageRepository struct {
	pool *pgxpool.Pool
}

// NewImageRepository creates a new PostgreSQL image repository.
func NewImageRepository(pool *pgxpool.Pool) *ImageRepository {
	return &ImageRepository{pool: pool}
}

// imageQuerier abstracts pgxpool.Pool and pgx.Tx for transaction support.
type imageQuerier interface {
	Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...interface{}) pgx.Row
	Exec(ctx context.Context, sql string, args ...interface{}) (pgconn.CommandTag, error)
}

// Create creates a new image for a product.
func (r *ImageRepository) Create(ctx context.Context, params *domain.CreateImageParams) (*domain.ProductImage, error) {
	return r.createWithQuerier(ctx, r.pool, params)
}

// CreateTx creates a new image within a transaction.
func (r *ImageRepository) CreateTx(ctx context.Context, tx pgx.Tx, params *domain.CreateImageParams) (*domain.ProductImage, error) {
	return r.createWithQuerier(ctx, tx, params)
}

func (r *ImageRepository) createWithQuerier(ctx context.Context, q imageQuerier, params *domain.CreateImageParams) (*domain.ProductImage, error) {
	query := `
		INSERT INTO admin_product_images (product_id, image_url, display_order, is_primary)
		VALUES ($1, $2, $3, $4)
		RETURNING image_id, product_id, image_url, display_order, is_primary, created_at`

	img := &domain.ProductImage{}
	err := q.QueryRow(ctx, query, params.ProductID, params.ImageURL, params.DisplayOrder, params.IsPrimary).Scan(
		&img.ImageID, &img.ProductID, &img.ImageURL, &img.DisplayOrder, &img.IsPrimary, &img.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create image: %w", err)
	}
	return img, nil
}

// GetByID retrieves an image by its ID.
func (r *ImageRepository) GetByID(ctx context.Context, id int32) (*domain.ProductImage, error) {
	query := `SELECT image_id, product_id, image_url, display_order, is_primary, created_at
		FROM admin_product_images WHERE image_id = $1`

	img := &domain.ProductImage{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&img.ImageID, &img.ProductID, &img.ImageURL, &img.DisplayOrder, &img.IsPrimary, &img.CreatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, domain.ErrImageNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get image: %w", err)
	}
	return img, nil
}

// GetByProductID retrieves all images for a product ordered by display_order.
func (r *ImageRepository) GetByProductID(ctx context.Context, productID int32) ([]domain.ProductImage, error) {
	return r.getByProductIDWithQuerier(ctx, r.pool, productID)
}

// GetByProductIDTx retrieves all images for a product within a transaction.
func (r *ImageRepository) GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.ProductImage, error) {
	return r.getByProductIDWithQuerier(ctx, tx, productID)
}

func (r *ImageRepository) getByProductIDWithQuerier(ctx context.Context, q imageQuerier, productID int32) ([]domain.ProductImage, error) {
	query := `SELECT image_id, product_id, image_url, display_order, is_primary, created_at
		FROM admin_product_images WHERE product_id = $1 ORDER BY display_order`

	rows, err := q.Query(ctx, query, productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var images []domain.ProductImage
	for rows.Next() {
		var img domain.ProductImage
		if err := rows.Scan(&img.ImageID, &img.ProductID, &img.ImageURL, &img.DisplayOrder, &img.IsPrimary, &img.CreatedAt); err != nil {
			return nil, err
		}
		images = append(images, img)
	}
	return images, nil
}

// GetPrimaryByProductID retrieves the primary image for a product.
func (r *ImageRepository) GetPrimaryByProductID(ctx context.Context, productID int32) (*domain.ProductImage, error) {
	query := `SELECT image_id, product_id, image_url, display_order, is_primary, created_at
		FROM admin_product_images WHERE product_id = $1 AND is_primary = true LIMIT 1`

	img := &domain.ProductImage{}
	err := r.pool.QueryRow(ctx, query, productID).Scan(
		&img.ImageID, &img.ProductID, &img.ImageURL, &img.DisplayOrder, &img.IsPrimary, &img.CreatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, nil // No primary image is not an error
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get primary image: %w", err)
	}
	return img, nil
}

// Update updates an image.
func (r *ImageRepository) Update(ctx context.Context, id int32, params *domain.UpdateImageParams) error {
	return r.updateWithQuerier(ctx, r.pool, id, params)
}

// UpdateTx updates an image within a transaction.
func (r *ImageRepository) UpdateTx(ctx context.Context, tx pgx.Tx, id int32, params *domain.UpdateImageParams) error {
	return r.updateWithQuerier(ctx, tx, id, params)
}

func (r *ImageRepository) updateWithQuerier(ctx context.Context, q imageQuerier, id int32, params *domain.UpdateImageParams) error {
	query := `UPDATE admin_product_images SET 
		image_url = COALESCE($1, image_url), 
		display_order = COALESCE($2, display_order), 
		is_primary = COALESCE($3, is_primary) 
		WHERE image_id = $4`
	_, err := q.Exec(ctx, query, params.ImageURL, params.DisplayOrder, params.IsPrimary, id)
	return err
}

// Delete deletes an image.
func (r *ImageRepository) Delete(ctx context.Context, id int32) error {
	return r.deleteWithQuerier(ctx, r.pool, id)
}

// DeleteTx deletes an image within a transaction.
func (r *ImageRepository) DeleteTx(ctx context.Context, tx pgx.Tx, id int32) error {
	return r.deleteWithQuerier(ctx, tx, id)
}

func (r *ImageRepository) deleteWithQuerier(ctx context.Context, q imageQuerier, id int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_images WHERE image_id = $1", id)
	return err
}

// DeleteByProductID deletes all images for a product.
func (r *ImageRepository) DeleteByProductID(ctx context.Context, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, r.pool, productID)
}

// DeleteByProductIDTx deletes all images for a product within a transaction.
func (r *ImageRepository) DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error {
	return r.deleteByProductIDWithQuerier(ctx, tx, productID)
}

func (r *ImageRepository) deleteByProductIDWithQuerier(ctx context.Context, q imageQuerier, productID int32) error {
	_, err := q.Exec(ctx, "DELETE FROM admin_product_images WHERE product_id = $1", productID)
	return err
}

// SetPrimary sets an image as the primary for a product, unsetting any existing primary.
func (r *ImageRepository) SetPrimary(ctx context.Context, productID int32, imageID int32) error {
	return r.setPrimaryWithQuerier(ctx, r.pool, productID, imageID)
}

// SetPrimaryTx sets an image as the primary within a transaction.
func (r *ImageRepository) SetPrimaryTx(ctx context.Context, tx pgx.Tx, productID int32, imageID int32) error {
	return r.setPrimaryWithQuerier(ctx, tx, productID, imageID)
}

func (r *ImageRepository) setPrimaryWithQuerier(ctx context.Context, q imageQuerier, productID int32, imageID int32) error {
	// First unset all primary images for this product
	_, err := q.Exec(ctx, "UPDATE admin_product_images SET is_primary = false WHERE product_id = $1", productID)
	if err != nil {
		return fmt.Errorf("failed to unset primary images: %w", err)
	}

	// Set the specified image as primary
	_, err = q.Exec(ctx, "UPDATE admin_product_images SET is_primary = true WHERE image_id = $1 AND product_id = $2", imageID, productID)
	if err != nil {
		return fmt.Errorf("failed to set primary image: %w", err)
	}

	return nil
}

// Reorder updates the display_order of images based on the provided ordered list of IDs.
func (r *ImageRepository) Reorder(ctx context.Context, productID int32, orderedIDs []int32) error {
	return r.reorderWithQuerier(ctx, r.pool, productID, orderedIDs)
}

// ReorderTx reorders images within a transaction.
func (r *ImageRepository) ReorderTx(ctx context.Context, tx pgx.Tx, productID int32, orderedIDs []int32) error {
	return r.reorderWithQuerier(ctx, tx, productID, orderedIDs)
}

func (r *ImageRepository) reorderWithQuerier(ctx context.Context, q imageQuerier, productID int32, orderedIDs []int32) error {
	for i, id := range orderedIDs {
		_, err := q.Exec(ctx, "UPDATE admin_product_images SET display_order = $1 WHERE image_id = $2 AND product_id = $3", int32(i), id, productID)
		if err != nil {
			return fmt.Errorf("failed to reorder image %d: %w", id, err)
		}
	}
	return nil
}

// BulkCreate creates multiple images for a product.
func (r *ImageRepository) BulkCreate(ctx context.Context, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error) {
	return r.bulkCreateWithQuerier(ctx, r.pool, productID, images)
}

// BulkCreateTx creates multiple images within a transaction.
func (r *ImageRepository) BulkCreateTx(ctx context.Context, tx pgx.Tx, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error) {
	return r.bulkCreateWithQuerier(ctx, tx, productID, images)
}

func (r *ImageRepository) bulkCreateWithQuerier(ctx context.Context, q imageQuerier, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error) {
	var result []domain.ProductImage
	for _, params := range images {
		params.ProductID = productID
		img, err := r.createWithQuerier(ctx, q, &params)
		if err != nil {
			return nil, err
		}
		result = append(result, *img)
	}
	return result, nil
}

// ReplaceAll deletes all existing images for a product and creates new ones.
func (r *ImageRepository) ReplaceAll(ctx context.Context, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error) {
	return r.replaceAllWithQuerier(ctx, r.pool, productID, images)
}

// ReplaceAllTx replaces all images within a transaction.
func (r *ImageRepository) ReplaceAllTx(ctx context.Context, tx pgx.Tx, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error) {
	return r.replaceAllWithQuerier(ctx, tx, productID, images)
}

func (r *ImageRepository) replaceAllWithQuerier(ctx context.Context, q imageQuerier, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error) {
	// Delete all existing images
	if err := r.deleteByProductIDWithQuerier(ctx, q, productID); err != nil {
		return nil, fmt.Errorf("failed to delete existing images: %w", err)
	}

	// Create new images
	return r.bulkCreateWithQuerier(ctx, q, productID, images)
}
