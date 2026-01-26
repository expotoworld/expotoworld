package service

import (
	"context"

	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/domain"
	"github.com/expotoworld/expotoworld_backend/services/catalog/internal/repository"
)

// StoreService provides business logic for stores.
type StoreService struct {
	storeRepo  repository.StoreRepository
	regionRepo repository.RegionRepository
}

// NewStoreService creates a new store service.
func NewStoreService(storeRepo repository.StoreRepository, regionRepo repository.RegionRepository) *StoreService {
	return &StoreService{
		storeRepo:  storeRepo,
		regionRepo: regionRepo,
	}
}

// CreateStore creates a new store.
func (s *StoreService) CreateStore(ctx context.Context, params *domain.CreateStoreParams) (*domain.Store, error) {
	return s.storeRepo.Create(ctx, params)
}

// GetStore retrieves a store by ID.
func (s *StoreService) GetStore(ctx context.Context, id int32) (*domain.Store, error) {
	return s.storeRepo.GetByID(ctx, id)
}

// GetStoreWithCounts retrieves a store with product count.
func (s *StoreService) GetStoreWithCounts(ctx context.Context, id int32) (*domain.StoreWithCounts, error) {
	store, err := s.storeRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	count, err := s.storeRepo.CountProducts(ctx, id)
	if err != nil {
		return nil, err
	}
	return &domain.StoreWithCounts{
		Store:        *store,
		ProductCount: int(count),
	}, nil
}

// ListStores lists stores with pagination.
func (s *StoreService) ListStores(ctx context.Context, page, pageSize int) (*repository.PaginatedResult[domain.Store], error) {
	pagination := repository.Pagination{Page: page, PageSize: pageSize}
	return s.storeRepo.List(ctx, nil, pagination)
}

// UpdateStore updates a store.
func (s *StoreService) UpdateStore(ctx context.Context, id int32, params *domain.UpdateStoreParams) (*domain.Store, error) {
	if err := s.storeRepo.Update(ctx, id, params); err != nil {
		return nil, err
	}
	return s.storeRepo.GetByID(ctx, id)
}

// DeleteStore deletes a store.
func (s *StoreService) DeleteStore(ctx context.Context, id int32) error {
	return s.storeRepo.Delete(ctx, id)
}

// GetStoresByRegion retrieves all stores in a region.
func (s *StoreService) GetStoresByRegion(ctx context.Context, regionID int32) ([]domain.Store, error) {
	// Get region first to find which store it belongs to
	region, err := s.regionRepo.GetByID(ctx, regionID)
	if err != nil {
		return nil, err
	}
	// If region has no store associated, return empty list
	if region.StoreID == nil {
		return []domain.Store{}, nil
	}
	// Get the store for this region
	store, err := s.storeRepo.GetByID(ctx, *region.StoreID)
	if err != nil {
		return nil, err
	}
	return []domain.Store{*store}, nil
}

// --------------------------------
// Region Methods
// --------------------------------

// CreateRegion creates a new region.
func (s *StoreService) CreateRegion(ctx context.Context, params *domain.CreateRegionParams) (*domain.Region, error) {
	return s.regionRepo.Create(ctx, params)
}

// GetRegion retrieves a region by ID.
func (s *StoreService) GetRegion(ctx context.Context, id int32) (*domain.Region, error) {
	return s.regionRepo.GetByID(ctx, id)
}

// UpdateRegion updates a region.
func (s *StoreService) UpdateRegion(ctx context.Context, id int32, params *domain.UpdateRegionParams) (*domain.Region, error) {
	if err := s.regionRepo.Update(ctx, id, params); err != nil {
		return nil, err
	}
	return s.regionRepo.GetByID(ctx, id)
}

// DeleteRegion deletes a region.
func (s *StoreService) DeleteRegion(ctx context.Context, id int32) error {
	return s.regionRepo.Delete(ctx, id)
}

// ListRegions lists all regions for all stores.
// Note: This fetches all stores and their regions since there's no global region list.
func (s *StoreService) ListRegions(ctx context.Context) ([]domain.Region, error) {
	// Get all stores first
	stores, err := s.storeRepo.List(ctx, nil, repository.Pagination{Page: 1, PageSize: 1000})
	if err != nil {
		return nil, err
	}

	var allRegions []domain.Region
	for _, store := range stores.Items {
		regions, err := s.regionRepo.GetByStoreID(ctx, store.StoreID)
		if err != nil {
			return nil, err
		}
		allRegions = append(allRegions, regions...)
	}
	return allRegions, nil
}

// ListRegionsByStore lists all regions for a store.
func (s *StoreService) ListRegionsByStore(ctx context.Context, storeID int32) ([]domain.Region, error) {
	return s.regionRepo.GetByStoreID(ctx, storeID)
}
