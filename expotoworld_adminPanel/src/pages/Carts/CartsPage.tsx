import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  Typography,
  IconButton,
  Tooltip,
  Avatar,
} from '@mui/material';
import {
  Search as SearchIcon,
  Visibility as ViewIcon,
  Delete as DeleteIcon,
  ShoppingBasket as CartIcon,
} from '@mui/icons-material';
import { PageHeader, DataTable, type Column } from '@components/common';
import type { Cart } from '@/types';

// TODO: NEED TO FULLY IMPLEMENT - This is a placeholder page

// TODO: DUMMY DATA - Replace with actual API calls
const mockCarts: Cart[] = [
  {
    id: 'cart-1',
    userId: 'user-1',
    customerName: 'John Doe',
    items: [
      { id: '1', productId: '1', productName: 'Wireless Headphones', quantity: 1, unitPrice: 99.99, totalPrice: 99.99 },
      { id: '2', productId: '4', productName: 'Water Bottle', quantity: 2, unitPrice: 19.99, totalPrice: 39.98 },
    ],
    totalItems: 3,
    totalPrice: 139.97,
    storeId: '1',
    storeName: 'MEGA Store Downtown',
    createdAt: '2024-01-15T10:30:00Z',
    updatedAt: '2024-01-15T14:30:00Z',
  },
  {
    id: 'cart-2',
    userId: 'user-2',
    customerName: 'Jane Smith',
    items: [
      { id: '1', productId: '3', productName: 'Smart Watch Pro', quantity: 1, unitPrice: 249.99, totalPrice: 249.99 },
    ],
    totalItems: 1,
    totalPrice: 249.99,
    storeId: '2',
    storeName: 'MARKET Central',
    createdAt: '2024-01-15T09:15:00Z',
    updatedAt: '2024-01-15T11:00:00Z',
  },
  {
    id: 'cart-3',
    userId: 'user-5',
    customerName: 'Charlie Davis',
    items: [
      { id: '1', productId: '2', productName: 'Organic Coffee', quantity: 3, unitPrice: 30.00, totalPrice: 90.00 },
      { id: '2', productId: '5', productName: 'Bluetooth Speaker', quantity: 1, unitPrice: 49.99, totalPrice: 49.99 },
    ],
    totalItems: 4,
    totalPrice: 139.99,
    storeId: '1',
    storeName: 'MEGA Store Downtown',
    createdAt: '2024-01-14T16:45:00Z',
    updatedAt: '2024-01-15T08:00:00Z',
  },
];

const CartsPage: React.FC = () => {
  const { t } = useTranslation();
  const [search, setSearch] = React.useState('');
  const [page, setPage] = React.useState(0);
  const [rowsPerPage, setRowsPerPage] = React.useState(10);

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const columns: Column<Cart>[] = [
    {
      id: 'customerName',
      label: t('carts.customer'),
      minWidth: 180,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar sx={{ width: 36, height: 36, bgcolor: 'primary.main' }}>
            {row.customerName.charAt(0)}
          </Avatar>
          <Typography variant="body2" fontWeight={500}>
            {row.customerName}
          </Typography>
        </Box>
      ),
    },
    {
      id: 'totalItems',
      label: t('carts.items'),
      minWidth: 80,
      align: 'center',
    },
    {
      id: 'totalPrice',
      label: t('carts.totalValue'),
      minWidth: 100,
      format: (value) => (
        <Typography variant="body2" fontWeight={500}>
          {formatCurrency(value)}
        </Typography>
      ),
    },
    {
      id: 'storeName',
      label: t('carts.store'),
      minWidth: 150,
    },
    {
      id: 'updatedAt',
      label: t('carts.lastUpdated'),
      minWidth: 140,
      format: (value) => formatDate(value),
    },
    {
      id: 'actions',
      label: t('common.actions'),
      minWidth: 100,
      align: 'right',
      format: () => (
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 0.5 }}>
          <Tooltip title={t('common.view')}>
            <IconButton size="small">
              <ViewIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('common.delete')}>
            <IconButton size="small" color="error">
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      ),
    },
  ];

  const filteredCarts = mockCarts.filter((cart) =>
    cart.customerName.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <Box>
      <PageHeader
        title={t('carts.title')}
        subtitle={t('carts.subtitle')}
        breadcrumbs={[
          { label: t('nav.dashboard'), path: '/' },
          { label: t('nav.carts') },
        ]}
      />

      {/* Stats Cards */}
      <Box sx={{ display: 'flex', gap: 3, mb: 3 }}>
        <Card elevation={0} sx={{ flex: 1 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <CartIcon sx={{ fontSize: 40, color: 'primary.main' }} />
              <Box>
                <Typography variant="h4" fontWeight={700}>
                  {mockCarts.length}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {t('carts.activeCarts')}
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
        <Card elevation={0} sx={{ flex: 1 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Box>
                <Typography variant="h4" fontWeight={700}>
                  {formatCurrency(mockCarts.reduce((sum, cart) => sum + cart.totalPrice, 0))}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {t('carts.potentialRevenue')}
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Box>

      {/* Filters */}
      <Card elevation={0} sx={{ mb: 3 }}>
        <CardContent>
          <TextField
            placeholder={t('carts.searchPlaceholder')}
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
        </CardContent>
      </Card>

      {/* Carts Table */}
      <DataTable
        columns={columns}
        data={filteredCarts}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredCarts.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('carts.noCarts')}
      />
    </Box>
  );
};

export default CartsPage;
