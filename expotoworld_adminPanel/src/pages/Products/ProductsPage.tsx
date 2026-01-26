import React, { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  Chip,
  IconButton,
  Tooltip,
  Avatar,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Star as FeaturedIcon,
  Add as AddIcon,
  Upload as UploadIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, FilterDropdown, type Column } from '@components/common';
import { productApi, categoryApi, storeApi, type Product, type Category, type Store, type PaginationInfo } from '@/services/catalogApi';
import ProductFormModal from './ProductFormModal';
import ProductDetailModal from './ProductDetailModal';

const ProductsPage: React.FC = () => {
  const { t } = useTranslation();
  
  // Data state
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  const [pagination, setPagination] = useState<PaginationInfo | null>(null);
  
  // Loading and error state
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Filter state
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [storeFilter, setStoreFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  
  // Dialog state
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [deleting, setDeleting] = useState(false);

  // Modal state
  const [formModalOpen, setFormModalOpen] = useState(false);
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [editProductId, setEditProductId] = useState<string | undefined>(undefined);
  const [viewProductId, setViewProductId] = useState<string | null>(null);
  const [parentIdForVariant, setParentIdForVariant] = useState<string | undefined>(undefined);

  // Fetch products from API
  const fetchProducts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params: Record<string, unknown> = {
        page: page + 1, // API uses 1-based pagination
        page_size: rowsPerPage,
      };
      
      // Add filters
      if (storeFilter !== 'all') {
        params.store_id = Number(storeFilter);
      }
      if (categoryFilter !== 'all') {
        params.category_id = Number(categoryFilter);
      }
      if (statusFilter === 'active') {
        params.is_active = true;
      } else if (statusFilter === 'inactive') {
        params.is_active = false;
      }
      if (search) {
        params.search = search;
      }
      
      const response = await productApi.getProducts(params);
      setProducts(response.items);
      setPagination(response.pagination);
    } catch (err) {
      console.error('Failed to fetch products:', err);
      setError(t('products.fetchError'));
    } finally {
      setLoading(false);
    }
  }, [page, rowsPerPage, storeFilter, categoryFilter, statusFilter, search, t]);

  // Fetch categories and stores for filters
  const fetchFiltersData = useCallback(async () => {
    try {
      const [categoriesRes, storesRes] = await Promise.all([
        categoryApi.getCategories({ page_size: 100 }),
        storeApi.getStores({ page_size: 100 }),
      ]);
      setCategories(categoriesRes.items);
      setStores(storesRes.items);
    } catch (err) {
      console.error('Failed to fetch filter data:', err);
      // Non-critical error, don't show to user
    }
  }, []);

  // Initial data fetch
  useEffect(() => {
    fetchFiltersData();
  }, [fetchFiltersData]);

  // Fetch products when filters change
  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  // Handle search with debounce
  useEffect(() => {
    const timer = setTimeout(() => {
      setPage(0); // Reset to first page on search
    }, 300);
    return () => clearTimeout(timer);
  }, [search]);

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const columns: Column<Product>[] = [
    {
      id: 'name',
      label: t('products.productName'),
      minWidth: 250,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar
            variant="rounded"
            src={row.primaryImageUrl || row.imageUrls[0]}
            sx={{ width: 48, height: 48 }}
          >
            {row.name.charAt(0)}
          </Avatar>
          <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <span style={{ fontWeight: 500 }}>{row.name}</span>
              {row.isFeatured && (
                <FeaturedIcon sx={{ fontSize: 16, color: 'warning.main' }} />
              )}
            </Box>
            <Box sx={{ fontSize: '0.75rem', color: 'text.secondary' }}>
              {row.shelfCode}
            </Box>
          </Box>
        </Box>
      ),
    },
    {
      id: 'currentPrice',
      label: t('products.price'),
      minWidth: 120,
      format: (_, row) => (
        <Box>
          <Box sx={{ fontWeight: 500 }}>{formatCurrency(row.currentPrice)}</Box>
          {row.originalPrice !== row.currentPrice && (
            <Box sx={{ fontSize: '0.75rem', color: 'text.secondary', textDecoration: 'line-through' }}>
              {formatCurrency(row.originalPrice)}
            </Box>
          )}
        </Box>
      ),
    },
    {
      id: 'stockLeft',
      label: t('products.stock'),
      minWidth: 100,
      format: (value) => (
        <Chip
          label={value}
          size="small"
          color={value === 0 ? 'error' : value < 10 ? 'warning' : 'default'}
          variant={value === 0 ? 'filled' : 'outlined'}
        />
      ),
    },
    {
      id: 'categoryId',
      label: t('products.category'),
      minWidth: 120,
      format: (value) => categories.find(c => c.id === value)?.name || value || '-',
    },
    {
      id: 'storeId',
      label: t('products.store'),
      minWidth: 150,
      format: (value) => stores.find(s => s.id === value)?.name || value || '-',
    },
    {
      id: 'isActive',
      label: t('common.status'),
      minWidth: 100,
      format: (value) => (
        <Chip
          label={value ? t('common.active') : t('common.inactive')}
          size="small"
          color={value ? 'success' : 'default'}
        />
      ),
    },
    {
      id: 'actions',
      label: t('common.actions'),
      minWidth: 120,
      format: (_, row) => (
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Tooltip title={t('common.view')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                setViewProductId(row.id);
                setDetailModalOpen(true);
              }}
            >
              <ViewIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('common.edit')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                setEditProductId(row.id);
                setParentIdForVariant(undefined);
                setFormModalOpen(true);
              }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('common.delete')}>
            <IconButton
              size="small"
              color="error"
              onClick={(e) => {
                e.stopPropagation();
                setSelectedProduct(row);
                setDeleteDialogOpen(true);
              }}
            >
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      ),
    },
  ];

  // Local filtering for stock status (API doesn't support this filter)
  const filteredProducts = products.filter((product) => {
    if (statusFilter === 'low_stock') return product.stockLeft < 10 && product.stockLeft > 0;
    if (statusFilter === 'out_of_stock') return product.stockLeft === 0;
    return true;
  });

  const handleDeleteConfirm = async () => {
    if (!selectedProduct) return;
    
    setDeleting(true);
    try {
      await productApi.archiveProduct(selectedProduct.id);
      // Refresh the products list after deletion
      await fetchProducts();
    } catch (err) {
      console.error('Failed to delete product:', err);
      setError(t('products.deleteError'));
    } finally {
      setDeleting(false);
      setDeleteDialogOpen(false);
      setSelectedProduct(null);
    }
  };

  // Modal handlers
  const handleOpenCreateModal = () => {
    setEditProductId(undefined);
    setParentIdForVariant(undefined);
    setFormModalOpen(true);
  };

  const handleOpenEditModal = (productId: string) => {
    setEditProductId(productId);
    setParentIdForVariant(undefined);
    setFormModalOpen(true);
    setDetailModalOpen(false);
  };

  const handleOpenAddVariantModal = (parentId: string) => {
    setEditProductId(undefined);
    setParentIdForVariant(parentId);
    setFormModalOpen(true);
    setDetailModalOpen(false);
  };

  const handleCloseFormModal = () => {
    setFormModalOpen(false);
    setEditProductId(undefined);
    setParentIdForVariant(undefined);
  };

  const handleCloseDetailModal = () => {
    setDetailModalOpen(false);
    setViewProductId(null);
  };

  const handleFormSuccess = () => {
    fetchProducts();
  };

  const actionMenuItems = [
    {
      label: t('products.create'),
      icon: <AddIcon />,
      onClick: handleOpenCreateModal,
    },
    {
      label: t('common.refresh'),
      icon: <RefreshIcon />,
      onClick: () => fetchProducts(),
    },
    {
      label: t('products.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  // Show loading state
  if (loading && products.length === 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('products.title')} actions={<ActionMenu actions={actionMenuItems} />} />

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Filters */}
      <Card elevation={0} sx={{ mb: 3 }}>
        <CardContent>
          <Box
            sx={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: 2,
              alignItems: 'center',
            }}
          >
            <TextField
              placeholder={t('products.searchPlaceholder')}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              size="small"
              sx={{ minWidth: 280 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon color="action" />
                  </InputAdornment>
                ),
              }}
            />
            <FilterDropdown
              label={t('products.category')}
              value={categoryFilter}
              options={[
                { value: 'all', label: t('common.all') },
                ...categories.map((category) => ({
                  value: category.id,
                  label: category.name,
                })),
              ]}
              onChange={(value) => {
                setCategoryFilter(value);
                setPage(0);
              }}
              minWidth={180}
            />
            <FilterDropdown
              label={t('products.store')}
              value={storeFilter}
              options={[
                { value: 'all', label: t('common.all') },
                ...stores.map((store) => ({
                  value: store.id,
                  label: store.name,
                })),
              ]}
              onChange={(value) => {
                setStoreFilter(value);
                setPage(0);
              }}
              minWidth={180}
            />
            <FilterDropdown
              label={t('common.status')}
              value={statusFilter}
              options={[
                { value: 'all', label: t('common.all') },
                { value: 'active', label: t('common.active') },
                { value: 'inactive', label: t('common.inactive') },
                { value: 'low_stock', label: t('products.lowStock') },
                { value: 'out_of_stock', label: t('products.outOfStock') },
              ]}
              onChange={(value) => {
                setStatusFilter(value);
                setPage(0);
              }}
              minWidth={180}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Products Table */}
      <DataTable
        columns={columns}
        data={filteredProducts}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={pagination?.total || filteredProducts.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('products.noProducts')}
        onRowClick={(row) => {
          setViewProductId(row.id);
          setDetailModalOpen(true);
        }}
        selectable
        loading={loading}
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('products.deleteTitle')}
        message={t('products.deleteMessage', { name: selectedProduct?.name })}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedProduct(null);
        }}
        loading={deleting}
      />

      {/* Product Form Modal (Create/Edit) */}
      <ProductFormModal
        open={formModalOpen}
        productId={editProductId}
        parentId={parentIdForVariant}
        onClose={handleCloseFormModal}
        onSuccess={handleFormSuccess}
      />

      {/* Product Detail Modal */}
      <ProductDetailModal
        open={detailModalOpen}
        productId={viewProductId}
        onClose={handleCloseDetailModal}
        onEdit={handleOpenEditModal}
        onAddVariant={handleOpenAddVariantModal}
        onRefresh={fetchProducts}
      />

    </Box>
  );
};

export default ProductsPage;
