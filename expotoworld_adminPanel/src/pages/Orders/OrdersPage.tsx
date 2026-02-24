import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  IconButton,
  Tooltip,
  Typography,
} from '@mui/material';
import {
  Search as SearchIcon,
  Visibility as ViewIcon,
  LocalShipping as ShipIcon,
  CheckCircle as CompleteIcon,
  Cancel as CancelIcon,
  Add as AddIcon,
  Upload as UploadIcon,
} from '@mui/icons-material';
import { DataTable, StatusChip, ConfirmDialog, PageTitle, ActionMenu, FilterDropdown, type Column } from '@components/common';
import type { Order } from '@/types';

// TODO: DUMMY DATA - Replace with actual API calls
const mockOrders: Order[] = [
  {
    id: 'ORD-2024-001',
    userId: 'user-1',
    customerName: 'John Doe',
    customerEmail: 'john@example.com',
    customerPhone: '+1 234 567 8900',
    items: [
      { id: '1', productId: '1', productName: 'Premium Wireless Headphones', quantity: 1, unitPrice: 99.99, totalPrice: 99.99 },
      { id: '2', productId: '4', productName: 'Eco-Friendly Water Bottle', quantity: 2, unitPrice: 19.99, totalPrice: 39.98 },
    ],
    subtotal: 139.97,
    deliveryFee: 5.99,
    total: 145.96,
    status: 'pending',
    shippingAddress: '123 Main St, New York, NY 10001',
    paymentMethod: 'Credit Card',
    storeId: '1',
    storeName: 'MEGA Store Downtown',
    createdAt: '2024-01-15T10:30:00Z',
    updatedAt: '2024-01-15T10:30:00Z',
  },
  {
    id: 'ORD-2024-002',
    userId: 'user-2',
    customerName: 'Jane Smith',
    customerEmail: 'jane@example.com',
    items: [
      { id: '1', productId: '2', productName: 'Organic Coffee Beans 1kg', quantity: 3, unitPrice: 30.00, totalPrice: 90.00 },
    ],
    subtotal: 90.00,
    deliveryFee: 0,
    total: 90.00,
    status: 'processing',
    paymentMethod: 'E-Wallet',
    storeId: '1',
    storeName: 'MEGA Store Downtown',
    createdAt: '2024-01-15T09:15:00Z',
    updatedAt: '2024-01-15T11:00:00Z',
  },
  {
    id: 'ORD-2024-003',
    userId: 'user-3',
    customerName: 'Bob Wilson',
    customerEmail: 'bob@example.com',
    items: [
      { id: '1', productId: '3', productName: 'Smart Watch Pro', quantity: 1, unitPrice: 249.99, totalPrice: 249.99 },
    ],
    subtotal: 249.99,
    deliveryFee: 9.99,
    total: 259.98,
    status: 'shipped',
    shippingAddress: '456 Oak Ave, Los Angeles, CA 90001',
    paymentMethod: 'Credit Card',
    storeId: '2',
    storeName: 'MARKET Central',
    createdAt: '2024-01-14T16:45:00Z',
    updatedAt: '2024-01-15T08:00:00Z',
  },
  {
    id: 'ORD-2024-004',
    userId: 'user-4',
    customerName: 'Alice Brown',
    customerEmail: 'alice@example.com',
    items: [
      { id: '1', productId: '4', productName: 'Eco-Friendly Water Bottle', quantity: 2, unitPrice: 19.99, totalPrice: 39.98 },
    ],
    subtotal: 39.98,
    deliveryFee: 5.99,
    total: 45.97,
    status: 'delivered',
    shippingAddress: '789 Pine Rd, Chicago, IL 60601',
    paymentMethod: 'E-Wallet',
    storeId: '3',
    storeName: 'toGO Station',
    createdAt: '2024-01-14T14:20:00Z',
    updatedAt: '2024-01-15T12:30:00Z',
  },
  {
    id: 'ORD-2024-005',
    userId: 'user-5',
    customerName: 'Charlie Davis',
    customerEmail: 'charlie@example.com',
    items: [
      { id: '1', productId: '1', productName: 'Premium Wireless Headphones', quantity: 1, unitPrice: 99.99, totalPrice: 99.99 },
      { id: '2', productId: '5', productName: 'Bluetooth Speaker Mini', quantity: 1, unitPrice: 49.99, totalPrice: 49.99 },
    ],
    subtotal: 149.98,
    deliveryFee: 0,
    total: 149.98,
    status: 'completed',
    paymentMethod: 'Cash',
    storeId: '1',
    storeName: 'MEGA Store Downtown',
    createdAt: '2024-01-14T11:00:00Z',
    updatedAt: '2024-01-14T15:00:00Z',
  },
  {
    id: 'ORD-2024-006',
    userId: 'user-6',
    customerName: 'Diana Evans',
    customerEmail: 'diana@example.com',
    items: [
      { id: '1', productId: '2', productName: 'Organic Coffee Beans 1kg', quantity: 1, unitPrice: 30.00, totalPrice: 30.00 },
    ],
    subtotal: 30.00,
    deliveryFee: 5.99,
    total: 35.99,
    status: 'cancelled',
    paymentMethod: 'Credit Card',
    storeId: '2',
    storeName: 'MARKET Central',
    notes: 'Customer requested cancellation',
    createdAt: '2024-01-13T09:30:00Z',
    updatedAt: '2024-01-13T10:15:00Z',
  },
];

const statusOptions: { value: string; labelKey: string }[] = [
  { value: 'all', labelKey: 'common.all' },
  { value: 'pending', labelKey: 'orders.status.pending' },
  { value: 'confirmed', labelKey: 'orders.status.confirmed' },
  { value: 'processing', labelKey: 'orders.status.processing' },
  { value: 'ready_for_pickup', labelKey: 'orders.status.readyForPickup' },
  { value: 'shipped', labelKey: 'orders.status.shipped' },
  { value: 'delivered', labelKey: 'orders.status.delivered' },
  { value: 'completed', labelKey: 'orders.status.completed' },
  { value: 'cancelled', labelKey: 'orders.status.cancelled' },
];

const OrdersPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [storeFilter, setStoreFilter] = useState('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [actionDialogOpen, setActionDialogOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [actionType, setActionType] = useState<'ship' | 'complete' | 'cancel'>('ship');

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const columns: Column<Order>[] = [
    {
      id: 'id',
      label: t('orders.orderId'),
      minWidth: 130,
      format: (value) => (
        <Typography variant="body2" fontWeight={600} sx={{ fontFamily: 'monospace' }}>
          {value}
        </Typography>
      ),
    },
    {
      id: 'customerName',
      label: t('orders.customer'),
      minWidth: 150,
      format: (_, row) => (
        <Box>
          <Typography variant="body2" fontWeight={500}>
            {row.customerName}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            {row.customerEmail}
          </Typography>
        </Box>
      ),
    },
    {
      id: 'items',
      label: t('orders.items'),
      minWidth: 80,
      align: 'center',
      format: (value) => value.length,
    },
    {
      id: 'total',
      label: t('orders.total'),
      minWidth: 100,
      format: (value) => (
        <Typography variant="body2" fontWeight={500}>
          {formatCurrency(value)}
        </Typography>
      ),
    },
    {
      id: 'status',
      label: t('common.status'),
      minWidth: 130,
      format: (value) => <StatusChip status={value} />,
    },
    {
      id: 'storeName',
      label: t('orders.store'),
      minWidth: 150,
    },
    {
      id: 'createdAt',
      label: t('orders.orderDate'),
      minWidth: 150,
      format: (value) => formatDate(value),
    },
    {
      id: 'actions',
      label: t('common.actions'),
      minWidth: 150,
      format: (_, row) => (
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Tooltip title={t('common.view')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                navigate(`/orders/${row.id}`);
              }}
            >
              <ViewIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          {(row.status === 'processing' || row.status === 'confirmed') && (
            <Tooltip title={t('orders.markAsShipped')}>
              <IconButton
                size="small"
                color="primary"
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedOrder(row);
                  setActionType('ship');
                  setActionDialogOpen(true);
                }}
              >
                <ShipIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          {row.status === 'delivered' && (
            <Tooltip title={t('orders.markAsCompleted')}>
              <IconButton
                size="small"
                color="success"
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedOrder(row);
                  setActionType('complete');
                  setActionDialogOpen(true);
                }}
              >
                <CompleteIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          {(row.status === 'pending' || row.status === 'confirmed') && (
            <Tooltip title={t('orders.cancelOrder')}>
              <IconButton
                size="small"
                color="error"
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedOrder(row);
                  setActionType('cancel');
                  setActionDialogOpen(true);
                }}
              >
                <CancelIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
        </Box>
      ),
    },
  ];

  // Filter orders
  const filteredOrders = mockOrders.filter((order) => {
    const matchesSearch = 
      order.id.toLowerCase().includes(search.toLowerCase()) ||
      order.customerName.toLowerCase().includes(search.toLowerCase()) ||
      order.customerEmail.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || order.status === statusFilter;
    const matchesStore = storeFilter === 'all' || order.storeId === storeFilter;
    return matchesSearch && matchesStatus && matchesStore;
  });

  const getActionDialogContent = () => {
    switch (actionType) {
      case 'ship':
        return {
          title: t('orders.confirmShipTitle'),
          message: t('orders.confirmShipMessage', { id: selectedOrder?.id }),
          confirmText: t('orders.markAsShipped'),
          confirmColor: 'primary' as const,
        };
      case 'complete':
        return {
          title: t('orders.confirmCompleteTitle'),
          message: t('orders.confirmCompleteMessage', { id: selectedOrder?.id }),
          confirmText: t('orders.markAsCompleted'),
          confirmColor: 'success' as const,
        };
      case 'cancel':
        return {
          title: t('orders.confirmCancelTitle'),
          message: t('orders.confirmCancelMessage', { id: selectedOrder?.id }),
          confirmText: t('orders.cancelOrder'),
          confirmColor: 'error' as const,
        };
    }
  };

  const handleActionConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call update order status API
    // TODO: Implement ${actionType} order API call for order: ${selectedOrder?.id}
    setActionDialogOpen(false);
    setSelectedOrder(null);
  };

  const dialogContent = getActionDialogContent();

  // Get unique stores from orders for filter
  const stores = [...new Set(mockOrders.map(o => ({ id: o.storeId, name: o.storeName })))];
  const uniqueStores = stores.filter((store, index, self) =>
    index === self.findIndex(s => s.id === store.id)
  );

  // Action menu items
  const actionMenuItems = [
    {
      label: t('orders.createOrder'),
      icon: <AddIcon />,
      onClick: () => navigate('/orders/new'),
    },
    {
      label: t('orders.uploadOrders'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload orders from file
      },
    },
  ];

  return (
    <Box>
      {/* Page Title with Action Menu */}
      <PageTitle 
        title={t('orders.title')} 
        actions={<ActionMenu actions={actionMenuItems} />}
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
              placeholder={t('orders.searchPlaceholder')}
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
              label={t('common.status')}
              value={statusFilter}
              options={statusOptions.map(opt => ({ value: opt.value, label: t(opt.labelKey) }))}
              onChange={(value) => {
                setStatusFilter(value);
                setPage(0);
              }}
              minWidth={180}
            />
            <FilterDropdown
              label={t('orders.store')}
              value={storeFilter}
              options={[
                { value: 'all', label: t('common.all') },
                ...uniqueStores.map(store => ({ value: store.id, label: store.name }))
              ]}
              onChange={setStoreFilter}
              minWidth={180}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Orders Table */}
      <DataTable
        columns={columns}
        data={filteredOrders}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredOrders.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('orders.noOrders')}
        onRowClick={(row) => navigate(`/orders/${row.id}`)}
        selectable
      />

      {/* Action Confirmation Dialog */}
      <ConfirmDialog
        open={actionDialogOpen}
        title={dialogContent.title}
        message={dialogContent.message}
        confirmText={dialogContent.confirmText}
        confirmColor={dialogContent.confirmColor}
        onConfirm={handleActionConfirm}
        onCancel={() => {
          setActionDialogOpen(false);
          setSelectedOrder(null);
        }}
      />
    </Box>
  );
};

export default OrdersPage;
