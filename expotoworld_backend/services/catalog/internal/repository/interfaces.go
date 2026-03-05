package repository

import (
	"context"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/jackc/pgx/v5"
)

// Pagination contains pagination parameters.
type Pagination struct {
	Page     int
	PageSize int
}

// PaginatedResult contains a paginated result.
type PaginatedResult[T any] struct {
	Items      []T
	TotalCount int64
	Page       int
	PageSize   int
	TotalPages int
}

// ProductRepository defines the interface for product data access.
type ProductRepository interface {
	Create(ctx context.Context, params *domain.CreateProductParams) (*domain.Product, error)
	CreateTx(ctx context.Context, tx pgx.Tx, params *domain.CreateProductParams) (*domain.Product, error)
	GetByID(ctx context.Context, id int32) (*domain.Product, error)
	GetByUUID(ctx context.Context, uuid string) (*domain.Product, error)
	GetBySKU(ctx context.Context, sku string) (*domain.Product, error)
	GetWithRelations(ctx context.Context, id int32) (*domain.ProductWithRelations, error)
	List(ctx context.Context, filter *domain.ProductFilter, pagination Pagination, sort *domain.ProductSort) (*PaginatedResult[domain.Product], error)
	Update(ctx context.Context, id int32, params *domain.UpdateProductParams) error
	UpdateTx(ctx context.Context, tx pgx.Tx, id int32, params *domain.UpdateProductParams) error
	Delete(ctx context.Context, id int32) error
	Archive(ctx context.Context, id int32) error
	ArchiveTx(ctx context.Context, tx pgx.Tx, id int32) error
	GetChildrenByParentID(ctx context.Context, parentID int32) ([]domain.Product, error)
	GetChildrenByParentIDTx(ctx context.Context, tx pgx.Tx, parentID int32) ([]domain.Product, error)
	UpdateParentAggregates(ctx context.Context, parentID int32, params *domain.UpdateParentAggregatesParams) error
	UpdateParentAggregatesTx(ctx context.Context, tx pgx.Tx, parentID int32, params *domain.UpdateParentAggregatesParams) error
	CountByStore(ctx context.Context, storeID int32) (int64, error)
	SetDefaultVariant(ctx context.Context, parentID int32, childID int32) error
	SetDefaultVariantTx(ctx context.Context, tx pgx.Tx, parentID int32, childID int32) error
}

// CategoryRepository defines the interface for category data access.
type CategoryRepository interface {
	Create(ctx context.Context, params *domain.CreateCategoryParams) (*domain.Category, error)
	GetByID(ctx context.Context, id int32) (*domain.Category, error)
	GetWithSubcategories(ctx context.Context, id int32) (*domain.CategoryWithSubcategories, error)
	List(ctx context.Context, filter *domain.CategoryFilter, pagination Pagination) (*PaginatedResult[domain.Category], error)
	ListWithCounts(ctx context.Context, filter *domain.CategoryFilter, pagination Pagination) (*PaginatedResult[domain.CategoryWithCounts], error)
	ListAll(ctx context.Context, filter *domain.CategoryFilter) ([]domain.Category, error)
	Update(ctx context.Context, id int32, params *domain.UpdateCategoryParams) error
	Delete(ctx context.Context, id int32) error
	Reorder(ctx context.Context, orderedIDs []int32) error
	GetCategoryTree(ctx context.Context, filter *domain.CategoryFilter) ([]domain.CategoryWithSubcategories, error)
}

// SubcategoryRepository defines the interface for subcategory data access.
type SubcategoryRepository interface {
	Create(ctx context.Context, params *domain.CreateSubcategoryParams) (*domain.Subcategory, error)
	GetByID(ctx context.Context, id int32) (*domain.Subcategory, error)
	GetByCategoryID(ctx context.Context, categoryID int32) ([]domain.Subcategory, error)
	List(ctx context.Context, filter *domain.SubcategoryFilter, pagination Pagination) (*PaginatedResult[domain.Subcategory], error)
	Update(ctx context.Context, id int32, params *domain.UpdateSubcategoryParams) error
	Delete(ctx context.Context, id int32) error
	Move(ctx context.Context, subcategoryID int32, targetCategoryID int32) error
	Reorder(ctx context.Context, categoryID int32, orderedIDs []int32) error
}

// CollectionRepository defines the interface for collection data access.
type CollectionRepository interface {
	Create(ctx context.Context, params *domain.CreateCollectionParams) (*domain.Collection, error)
	GetByID(ctx context.Context, id int32) (*domain.Collection, error)
	GetBySubcategoryID(ctx context.Context, subcategoryID int32) ([]domain.Collection, error)
	List(ctx context.Context, filter *domain.CollectionFilter, pagination Pagination) (*PaginatedResult[domain.Collection], error)
	Update(ctx context.Context, id int32, params *domain.UpdateCollectionParams) error
	Delete(ctx context.Context, id int32) error
	Move(ctx context.Context, collectionID int32, targetSubcategoryID int32) error
	Reorder(ctx context.Context, subcategoryID int32, orderedIDs []int32) error
}

// StoreRepository defines the interface for store data access.
type StoreRepository interface {
	Create(ctx context.Context, params *domain.CreateStoreParams) (*domain.Store, error)
	GetByID(ctx context.Context, id int32) (*domain.Store, error)
	GetByOrganizationID(ctx context.Context, orgID int32) ([]domain.Store, error)
	List(ctx context.Context, filter *domain.StoreFilter, pagination Pagination) (*PaginatedResult[domain.Store], error)
	Update(ctx context.Context, id int32, params *domain.UpdateStoreParams) error
	Delete(ctx context.Context, id int32) error
	CountProducts(ctx context.Context, storeID int32) (int64, error)
	CountCategories(ctx context.Context, storeID int32) (int64, error)
}

// RegionRepository defines the interface for region data access.
type RegionRepository interface {
	Create(ctx context.Context, params *domain.CreateRegionParams) (*domain.Region, error)
	GetByID(ctx context.Context, id int32) (*domain.Region, error)
	GetByStoreID(ctx context.Context, storeID int32) ([]domain.Region, error)
	List(ctx context.Context, filter *domain.RegionFilter, pagination Pagination) (*PaginatedResult[domain.Region], error)
	ListAll(ctx context.Context) ([]domain.Region, error)
	Update(ctx context.Context, id int32, params *domain.UpdateRegionParams) error
	Delete(ctx context.Context, id int32) error
}

// AttributeRepository defines the interface for product attribute data access.
type AttributeRepository interface {
	Create(ctx context.Context, params *domain.CreateAttributeParams) (*domain.ProductAttribute, error)
	CreateTx(ctx context.Context, tx pgx.Tx, params *domain.CreateAttributeParams) (*domain.ProductAttribute, error)
	GetByID(ctx context.Context, id int32) (*domain.ProductAttribute, error)
	GetByProductID(ctx context.Context, productID int32) ([]domain.ProductAttribute, error)
	GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.ProductAttribute, error)
	Update(ctx context.Context, id int32, params *domain.UpdateAttributeParams) error
	UpdateTx(ctx context.Context, tx pgx.Tx, id int32, params *domain.UpdateAttributeParams) error
	Delete(ctx context.Context, id int32) error
	DeleteTx(ctx context.Context, tx pgx.Tx, id int32) error
	DeleteByProductID(ctx context.Context, productID int32) error
	DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error
	BulkCreate(ctx context.Context, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error)
	BulkCreateTx(ctx context.Context, tx pgx.Tx, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error)
	ReplaceAll(ctx context.Context, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error)
	ReplaceAllTx(ctx context.Context, tx pgx.Tx, productID int32, attributes []domain.CreateAttributeParams) ([]domain.ProductAttribute, error)
}

// ImageRepository defines the interface for product image data access.
type ImageRepository interface {
	Create(ctx context.Context, params *domain.CreateImageParams) (*domain.ProductImage, error)
	CreateTx(ctx context.Context, tx pgx.Tx, params *domain.CreateImageParams) (*domain.ProductImage, error)
	GetByID(ctx context.Context, id int32) (*domain.ProductImage, error)
	GetByProductID(ctx context.Context, productID int32) ([]domain.ProductImage, error)
	GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.ProductImage, error)
	GetPrimaryByProductID(ctx context.Context, productID int32) (*domain.ProductImage, error)
	Update(ctx context.Context, id int32, params *domain.UpdateImageParams) error
	UpdateTx(ctx context.Context, tx pgx.Tx, id int32, params *domain.UpdateImageParams) error
	Delete(ctx context.Context, id int32) error
	DeleteTx(ctx context.Context, tx pgx.Tx, id int32) error
	DeleteByProductID(ctx context.Context, productID int32) error
	DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error
	SetPrimary(ctx context.Context, productID int32, imageID int32) error
	SetPrimaryTx(ctx context.Context, tx pgx.Tx, productID int32, imageID int32) error
	Reorder(ctx context.Context, productID int32, orderedIDs []int32) error
	ReorderTx(ctx context.Context, tx pgx.Tx, productID int32, orderedIDs []int32) error
	BulkCreate(ctx context.Context, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error)
	BulkCreateTx(ctx context.Context, tx pgx.Tx, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error)
	ReplaceAll(ctx context.Context, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error)
	ReplaceAllTx(ctx context.Context, tx pgx.Tx, productID int32, images []domain.CreateImageParams) ([]domain.ProductImage, error)
}

// CategoryMappingRepository defines the interface for product-category mapping data access.
type CategoryMappingRepository interface {
	Create(ctx context.Context, productID int32, categoryID int32) (*domain.CategoryMapping, error)
	CreateTx(ctx context.Context, tx pgx.Tx, productID int32, categoryID int32) (*domain.CategoryMapping, error)
	GetByProductID(ctx context.Context, productID int32) ([]domain.CategoryMapping, error)
	GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.CategoryMapping, error)
	GetByCategoryID(ctx context.Context, categoryID int32) ([]domain.CategoryMapping, error)
	Delete(ctx context.Context, productID int32, categoryID int32) error
	DeleteTx(ctx context.Context, tx pgx.Tx, productID int32, categoryID int32) error
	DeleteByProductID(ctx context.Context, productID int32) error
	DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error
	DeleteByCategoryID(ctx context.Context, categoryID int32) error
	SetCategories(ctx context.Context, productID int32, categoryIDs []int32) error
	SetCategoriesTx(ctx context.Context, tx pgx.Tx, productID int32, categoryIDs []int32) error
}

// SubcategoryMappingRepository defines the interface for product-subcategory mapping data access.
type SubcategoryMappingRepository interface {
	Create(ctx context.Context, productID int32, subcategoryID int32) (*domain.SubcategoryMapping, error)
	CreateTx(ctx context.Context, tx pgx.Tx, productID int32, subcategoryID int32) (*domain.SubcategoryMapping, error)
	GetByProductID(ctx context.Context, productID int32) ([]domain.SubcategoryMapping, error)
	GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.SubcategoryMapping, error)
	GetBySubcategoryID(ctx context.Context, subcategoryID int32) ([]domain.SubcategoryMapping, error)
	Delete(ctx context.Context, productID int32, subcategoryID int32) error
	DeleteTx(ctx context.Context, tx pgx.Tx, productID int32, subcategoryID int32) error
	DeleteByProductID(ctx context.Context, productID int32) error
	DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error
	DeleteBySubcategoryID(ctx context.Context, subcategoryID int32) error
	SetSubcategories(ctx context.Context, productID int32, subcategoryIDs []int32) error
	SetSubcategoriesTx(ctx context.Context, tx pgx.Tx, productID int32, subcategoryIDs []int32) error
}

// CollectionMappingRepository defines the interface for product-collection mapping data access.
type CollectionMappingRepository interface {
	Create(ctx context.Context, productID int32, collectionID int32) (*domain.CollectionMapping, error)
	CreateTx(ctx context.Context, tx pgx.Tx, productID int32, collectionID int32) (*domain.CollectionMapping, error)
	GetByProductID(ctx context.Context, productID int32) ([]domain.CollectionMapping, error)
	GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.CollectionMapping, error)
	GetByCollectionID(ctx context.Context, collectionID int32) ([]domain.CollectionMapping, error)
	Delete(ctx context.Context, productID int32, collectionID int32) error
	DeleteTx(ctx context.Context, tx pgx.Tx, productID int32, collectionID int32) error
	DeleteByProductID(ctx context.Context, productID int32) error
	DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error
	DeleteByCollectionID(ctx context.Context, collectionID int32) error
	SetCollections(ctx context.Context, productID int32, collectionIDs []int32) error
	SetCollectionsTx(ctx context.Context, tx pgx.Tx, productID int32, collectionIDs []int32) error
}

// SubcollectionRepository defines the interface for subcollection data access.
type SubcollectionRepository interface {
	Create(ctx context.Context, params *domain.CreateSubcollectionParams) (*domain.Subcollection, error)
	GetByID(ctx context.Context, id int32) (*domain.Subcollection, error)
	GetByCollectionID(ctx context.Context, collectionID int32) ([]domain.Subcollection, error)
	List(ctx context.Context, filter *domain.SubcollectionFilter, pagination Pagination) (*PaginatedResult[domain.Subcollection], error)
	Update(ctx context.Context, id int32, params *domain.UpdateSubcollectionParams) error
	Delete(ctx context.Context, id int32) error
	Move(ctx context.Context, subcollectionID int32, targetCollectionID int32) error
	Reorder(ctx context.Context, collectionID int32, orderedIDs []int32) error
}

// SubcollectionMappingRepository defines the interface for product-subcollection mapping data access.
type SubcollectionMappingRepository interface {
	Create(ctx context.Context, productID int32, subcollectionID int32) (*domain.SubcollectionMapping, error)
	CreateTx(ctx context.Context, tx pgx.Tx, productID int32, subcollectionID int32) (*domain.SubcollectionMapping, error)
	GetByProductID(ctx context.Context, productID int32) ([]domain.SubcollectionMapping, error)
	GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.SubcollectionMapping, error)
	GetBySubcollectionID(ctx context.Context, subcollectionID int32) ([]domain.SubcollectionMapping, error)
	Delete(ctx context.Context, productID int32, subcollectionID int32) error
	DeleteTx(ctx context.Context, tx pgx.Tx, productID int32, subcollectionID int32) error
	DeleteByProductID(ctx context.Context, productID int32) error
	DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error
	DeleteBySubcollectionID(ctx context.Context, subcollectionID int32) error
	SetSubcollections(ctx context.Context, productID int32, subcollectionIDs []int32) error
	SetSubcollectionsTx(ctx context.Context, tx pgx.Tx, productID int32, subcollectionIDs []int32) error
}

// SpecificationRepository defines the interface for product specification data access.
// Specifications are Amazon-style product details (Brand, Material, etc.) that are
// purely informational and NOT used for variant generation.
type SpecificationRepository interface {
	Create(ctx context.Context, params *domain.CreateSpecificationParams) (*domain.ProductSpecification, error)
	CreateTx(ctx context.Context, tx pgx.Tx, params *domain.CreateSpecificationParams) (*domain.ProductSpecification, error)
	GetByID(ctx context.Context, id int32) (*domain.ProductSpecification, error)
	GetByProductID(ctx context.Context, productID int32) ([]domain.ProductSpecification, error)
	GetByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) ([]domain.ProductSpecification, error)
	Update(ctx context.Context, id int32, params *domain.UpdateSpecificationParams) error
	UpdateTx(ctx context.Context, tx pgx.Tx, id int32, params *domain.UpdateSpecificationParams) error
	Delete(ctx context.Context, id int32) error
	DeleteTx(ctx context.Context, tx pgx.Tx, id int32) error
	DeleteByProductID(ctx context.Context, productID int32) error
	DeleteByProductIDTx(ctx context.Context, tx pgx.Tx, productID int32) error
	BulkCreate(ctx context.Context, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error)
	BulkCreateTx(ctx context.Context, tx pgx.Tx, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error)
	ReplaceAll(ctx context.Context, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error)
	ReplaceAllTx(ctx context.Context, tx pgx.Tx, productID int32, specs []domain.CreateSpecificationParams) ([]domain.ProductSpecification, error)
	CopyFromProduct(ctx context.Context, sourceProductID, targetProductID int32) ([]domain.ProductSpecification, error)
	CopyFromProductTx(ctx context.Context, tx pgx.Tx, sourceProductID, targetProductID int32) ([]domain.ProductSpecification, error)
}
