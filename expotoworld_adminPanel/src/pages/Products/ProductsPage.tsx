import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Button,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  IconButton,
  Tooltip,
  Avatar,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Star as FeaturedIcon,
} from '@mui/icons-material';
import { PageHeader, DataTable, ConfirmDialog, type Column } from '@components/common';
import type { Product, Category, Store } from '@/types';

// TODO: DUMMY DATA - Replace with actual API calls
const mockProducts: Product[] = [
  {
    id: '1',
    name: 'Premium Wireless Headphones',
    description: 'High-quality noise-canceling headphones',
    originalPrice: 129.99,
    currentPrice: 99.99,
    stockLeft: 45,
    minimumOrderQuantity: 1,
    unit: 'piece',
    shelfCode: 'A1-001',
    imageUrls: ['https://placehold.co/100x100'],
    categoryId: '1',
    subcategoryId: '1-1',
    storeId: '1',
    isFeatured: true,
    isActive: true,
    createdAt: '2024-01-10T10:00:00Z',
    updatedAt: '2024-01-15T14:30:00Z',
  },
  {
    id: '2',
    name: 'Organic Coffee Beans 1kg',
    description: 'Premium arabica coffee beans',
    originalPrice: 35.0,
    currentPrice: 30.0,
    stockLeft: 120,
    minimumOrderQuantity: 1,
    unit: 'kg',
    shelfCode: 'B2-015',
    imageUrls: ['https://placehold.co/100x100'],
    categoryId: '2',
    subcategoryId: '2-1',
    storeId: '1',
    isFeatured: false,
    isActive: true,
    createdAt: '2024-01-08T09:00:00Z',
    updatedAt: '2024-01-14T11:20:00Z',
  },
  {
    id: '3',
    name: 'Smart Watch Pro',
    description: 'Advanced fitness tracking smartwatch',
    originalPrice: 299.99,
    currentPrice: 249.99,
    stockLeft: 5,
    minimumOrderQuantity: 1,
    unit: 'piece',
    shelfCode: 'C3-008',
    imageUrls: ['https://placehold.co/100x100'],
    categoryId: '1',
    subcategoryId: '1-2',
    storeId: '2',
    isFeatured: true,
    isActive: true,
    createdAt: '2024-01-05T15:00:00Z',
    updatedAt: '2024-01-15T09:45:00Z',
  },
  {
    id: '4',
    name: 'Eco-Friendly Water Bottle',
    description: 'Sustainable stainless steel water bottle',
    originalPrice: 24.99,
    currentPrice: 19.99,
    stockLeft: 200,
    minimumOrderQuantity: 1,
    unit: 'piece',
    shelfCode: 'D1-022',
    imageUrls: ['https://placehold.co/100x100'],
    categoryId: '3',
    subcategoryId: '3-1',
    storeId: '1',
    isFeatured: false,
    isActive: true,
    createdAt: '2024-01-12T08:30:00Z',
    updatedAt: '2024-01-15T16:00:00Z',
  },
  {
    id: '5',
    name: 'Bluetooth Speaker Mini',
    description: 'Portable wireless speaker',
    originalPrice: 59.99,
    currentPrice: 49.99,
    stockLeft: 0,
    minimumOrderQuantity: 1,
    unit: 'piece',
    shelfCode: 'A2-003',
    imageUrls: ['https://placehold.co/100x100'],
    categoryId: '1',
    subcategoryId: '1-3',
    storeId: '3',
    isFeatured: false,
    isActive: false,
    createdAt: '2024-01-03T11:00:00Z',
    updatedAt: '2024-01-10T13:15:00Z',
  },
];

const mockCategories: Category[] = [
  { id: '1', name: 'Electronics', productCount: 150, isActive: true, createdAt: '', updatedAt: '' },
  { id: '2', name: 'Food & Beverage', productCount: 280, isActive: true, createdAt: '', updatedAt: '' },
  { id: '3', name: 'Home & Living', productCount: 95, isActive: true, createdAt: '', updatedAt: '' },
];

const mockStores: Store[] = [
  { id: '1', name: 'MEGA Store Downtown', storeType: 'mega', address: '', latitude: 0, longitude: 0, isActive: true, createdAt: '', updatedAt: '' },
  { id: '2', name: 'MARKET Central', storeType: 'market', address: '', latitude: 0, longitude: 0, isActive: true, createdAt: '', updatedAt: '' },
  { id: '3', name: 'toGO Station', storeType: 'toGo', address: '', latitude: 0, longitude: 0, isActive: true, createdAt: '', updatedAt: '' },
];

const ProductsPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [storeFilter, setStoreFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);

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
            src={row.imageUrls[0]}
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
      format: (value) => mockCategories.find(c => c.id === value)?.name || value,
    },
    {
      id: 'storeId',
      label: t('products.store'),
      minWidth: 150,
      format: (value) => mockStores.find(s => s.id === value)?.name || value,
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
      align: 'right',
      format: (_, row) => (
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 0.5 }}>
          <Tooltip title={t('common.view')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                navigate(`/products/${row.id}`);
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
                navigate(`/products/${row.id}/edit`);
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

  // Filter products
  const filteredProducts = mockProducts.filter((product) => {
    const matchesSearch = product.name.toLowerCase().includes(search.toLowerCase()) ||
      product.shelfCode.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || product.categoryId === categoryFilter;
    const matchesStore = storeFilter === 'all' || product.storeId === storeFilter;
    const matchesStatus = statusFilter === 'all' ||
      (statusFilter === 'active' && product.isActive) ||
      (statusFilter === 'inactive' && !product.isActive) ||
      (statusFilter === 'low_stock' && product.stockLeft < 10) ||
      (statusFilter === 'out_of_stock' && product.stockLeft === 0);
    return matchesSearch && matchesCategory && matchesStore && matchesStatus;
  });

  const handleDeleteConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call delete API
    console.log('Deleting product:', selectedProduct?.id);
    setDeleteDialogOpen(false);
    setSelectedProduct(null);
  };

  return (
    <Box>
      <PageHeader
        title={t('products.title')}
        subtitle={t('products.subtitle')}
        breadcrumbs={[
          { label: t('nav.dashboard'), path: '/' },
          { label: t('nav.products') },
        ]}
        actions={
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => navigate('/products/new')}
          >
            {t('products.addProduct')}
          </Button>
        }
      />

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
              sx={{ minWidth: 250 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon color="action" />
                  </InputAdornment>
                ),
              }}
            />
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>{t('products.category')}</InputLabel>
              <Select
                value={categoryFilter}
                label={t('products.category')}
                onChange={(e) => setCategoryFilter(e.target.value)}
              >
                <MenuItem value="all">{t('common.all')}</MenuItem>
                {mockCategories.map((category) => (
                  <MenuItem key={category.id} value={category.id}>
                    {category.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>{t('products.store')}</InputLabel>
              <Select
                value={storeFilter}
                label={t('products.store')}
                onChange={(e) => setStoreFilter(e.target.value)}
              >
                <MenuItem value="all">{t('common.all')}</MenuItem>
                {mockStores.map((store) => (
                  <MenuItem key={store.id} value={store.id}>
                    {store.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>{t('common.status')}</InputLabel>
              <Select
                value={statusFilter}
                label={t('common.status')}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <MenuItem value="all">{t('common.all')}</MenuItem>
                <MenuItem value="active">{t('common.active')}</MenuItem>
                <MenuItem value="inactive">{t('common.inactive')}</MenuItem>
                <MenuItem value="low_stock">{t('products.lowStock')}</MenuItem>
                <MenuItem value="out_of_stock">{t('products.outOfStock')}</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </CardContent>
      </Card>

      {/* Products Table */}
      <DataTable
        columns={columns}
        data={filteredProducts}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredProducts.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('products.noProducts')}
        onRowClick={(row) => navigate(`/products/${row.id}`)}
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
      />
    </Box>
  );
};

export default ProductsPage;
