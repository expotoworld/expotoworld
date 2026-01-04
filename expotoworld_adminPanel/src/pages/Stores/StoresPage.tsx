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
  Chip,
  alpha,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  LocationOn as LocationIcon,
  Store as StoreIcon,
  Add as AddIcon,
  Upload as UploadIcon,
} from '@mui/icons-material';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, FilterDropdown, type Column } from '@components/common';
import { storeTypeColors } from '@theme/colors';
import type { Store, StoreType } from '@/types';

// TODO: DUMMY DATA - Replace with actual API calls
const mockStores: Store[] = [
  {
    id: '1',
    name: 'MEGA Store Downtown',
    storeType: 'mega',
    address: '123 Main Street, Downtown, New York, NY 10001',
    latitude: 40.7128,
    longitude: -74.0060,
    imageUrl: 'https://placehold.co/400x200/1976d2/white?text=MEGA',
    operatingHours: '24/7',
    capacity: 5000,
    isActive: true,
    createdAt: '2023-06-15T10:00:00Z',
    updatedAt: '2024-01-15T14:30:00Z',
  },
  {
    id: '2',
    name: 'MARKET Central',
    storeType: 'market',
    address: '456 Oak Avenue, Midtown, New York, NY 10022',
    latitude: 40.7580,
    longitude: -73.9855,
    imageUrl: 'https://placehold.co/400x200/2e7d32/white?text=MARKET',
    operatingHours: '6:00 AM - 11:00 PM',
    capacity: 2000,
    isActive: true,
    createdAt: '2023-08-20T09:00:00Z',
    updatedAt: '2024-01-14T11:20:00Z',
  },
  {
    id: '3',
    name: 'toGO Station Penn',
    storeType: 'toGo',
    address: 'Penn Station, 7th Avenue, New York, NY 10001',
    latitude: 40.7506,
    longitude: -73.9935,
    imageUrl: 'https://placehold.co/400x200/7b1fa2/white?text=toGO',
    operatingHours: '5:00 AM - 12:00 AM',
    capacity: 500,
    isActive: true,
    createdAt: '2023-10-05T15:00:00Z',
    updatedAt: '2024-01-15T09:45:00Z',
  },
  {
    id: '4',
    name: 'XPRESS Times Square',
    storeType: 'xpress',
    address: 'Times Square, Broadway, New York, NY 10036',
    latitude: 40.7580,
    longitude: -73.9855,
    imageUrl: 'https://placehold.co/400x200/f9a825/black?text=XPRESS',
    operatingHours: '24/7',
    capacity: 100,
    isActive: true,
    createdAt: '2023-12-12T08:30:00Z',
    updatedAt: '2024-01-15T16:00:00Z',
  },
  {
    id: '5',
    name: 'MEGA Store Brooklyn',
    storeType: 'mega',
    address: '789 Atlantic Ave, Brooklyn, NY 11217',
    latitude: 40.6892,
    longitude: -73.9855,
    imageUrl: 'https://placehold.co/400x200/1976d2/white?text=MEGA',
    operatingHours: '24/7',
    capacity: 4500,
    isActive: false,
    createdAt: '2024-01-03T11:00:00Z',
    updatedAt: '2024-01-10T13:15:00Z',
  },
];

const StoresPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedStore, setSelectedStore] = useState<Store | null>(null);

  const getStoreTypeColor = (type: StoreType) => {
    return storeTypeColors[type] || storeTypeColors.mega;
  };

  const getStoreTypeLabel = (type: StoreType) => {
    const labels: Record<StoreType, string> = {
      mega: 'MEGA',
      market: 'MARKET',
      toGo: 'toGO',
      xpress: 'XPRESS',
    };
    return labels[type];
  };

  const columns: Column<Store>[] = [
    {
      id: 'name',
      label: t('stores.storeName'),
      minWidth: 200,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Box
            sx={{
              width: 48,
              height: 48,
              borderRadius: 2,
              bgcolor: alpha(getStoreTypeColor(row.storeType), 0.1),
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <StoreIcon sx={{ color: getStoreTypeColor(row.storeType) }} />
          </Box>
          <Box>
            <Typography variant="body2" fontWeight={500}>
              {row.name}
            </Typography>
            <Chip
              label={getStoreTypeLabel(row.storeType)}
              size="small"
              sx={{
                mt: 0.5,
                bgcolor: alpha(getStoreTypeColor(row.storeType), 0.1),
                color: getStoreTypeColor(row.storeType),
                fontWeight: 600,
                fontSize: '0.7rem',
              }}
            />
          </Box>
        </Box>
      ),
    },
    {
      id: 'address',
      label: t('stores.address'),
      minWidth: 250,
      format: (value) => (
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1 }}>
          <LocationIcon fontSize="small" color="action" sx={{ mt: 0.25 }} />
          <Typography variant="body2" color="text.secondary">
            {value}
          </Typography>
        </Box>
      ),
    },
    {
      id: 'operatingHours',
      label: t('stores.hours'),
      minWidth: 150,
    },
    {
      id: 'capacity',
      label: t('stores.capacity'),
      minWidth: 100,
      align: 'center',
      format: (value) => value?.toLocaleString() || '-',
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
                navigate(`/stores/${row.id}`);
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
                navigate(`/stores/${row.id}/edit`);
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
                setSelectedStore(row);
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

  // Filter stores
  const filteredStores = mockStores.filter((store) => {
    const matchesSearch =
      store.name.toLowerCase().includes(search.toLowerCase()) ||
      store.address.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || store.storeType === typeFilter;
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && store.isActive) ||
      (statusFilter === 'inactive' && !store.isActive);
    return matchesSearch && matchesType && matchesStatus;
  });

  const handleDeleteConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call delete API
    // TODO: Implement delete store API call for store: ${selectedStore?.id}
    setDeleteDialogOpen(false);
    setSelectedStore(null);
  };

  const actionMenuItems = [
    {
      label: t('stores.create'),
      icon: <AddIcon />,
      onClick: () => navigate('/stores/new'),
    },
    {
      label: t('stores.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('stores.title')} actions={<ActionMenu actions={actionMenuItems} />} />

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
              placeholder={t('stores.searchPlaceholder')}
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
              label={t('stores.storeType')}
              value={typeFilter}
              options={[
                { value: 'all', label: t('common.all') },
                { value: 'mega', label: 'MEGA' },
                { value: 'market', label: 'MARKET' },
                { value: 'toGo', label: 'toGO' },
                { value: 'xpress', label: 'XPRESS' },
              ]}
              onChange={(value) => setTypeFilter(value)}
              minWidth={180}
            />
            <FilterDropdown
              label={t('common.status')}
              value={statusFilter}
              options={[
                { value: 'all', label: t('common.all') },
                { value: 'active', label: t('common.active') },
                { value: 'inactive', label: t('common.inactive') },
              ]}
              onChange={(value) => setStatusFilter(value)}
              minWidth={180}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Stores Table */}
      <DataTable
        columns={columns}
        data={filteredStores}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredStores.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('stores.noStores') || 'No stores found'}
        onRowClick={(row) => navigate(`/stores/${row.id}`)}
        selectable
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('stores.deleteTitle') || 'Delete Store'}
        message={t('stores.deleteMessage', { name: selectedStore?.name }) || `Are you sure you want to delete "${selectedStore?.name}"?`}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedStore(null);
        }}
      />

    </Box>
  );
};

export default StoresPage;
