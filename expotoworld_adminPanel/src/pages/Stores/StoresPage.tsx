import React, { useState, useCallback, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
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
  CircularProgress,
  Alert,
  Avatar,
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
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, FilterDropdown, type Column } from '@components/common';
import { storeTypeColors } from '@theme/colors';
import { storeApi, type Store, type PaginationInfo } from '@/services/catalogApi';
import StoreFormModal from './StoreFormModal';
import StoreDetailModal from './StoreDetailModal';

// Store type mapping from ETW backend values to display labels
type StoreType = 'ETWMega' | 'ETWMarket' | 'ETWtoGO' | 'ETWXpress' | 'unknown';

const storeTypeLabels: Record<StoreType, string> = {
  ETWMega: 'MEGA',
  ETWMarket: 'MARKET',
  ETWtoGO: 'toGO',
  ETWXpress: 'XPRESS',
  unknown: 'Unknown',
};

// Map ETW store types to color keys
const storeTypeToColorKey: Record<StoreType, keyof typeof storeTypeColors> = {
  ETWMega: 'mega',
  ETWMarket: 'market',
  ETWtoGO: 'toGo',
  ETWXpress: 'xpress',
  unknown: 'mega',
};

const miniAppTypeLabels: Record<string, string> = {
  ETWtoB: 'toB',
  ETWtoC: 'toC',
  ETWtoU: 'toU',
};

const StoresPage: React.FC = () => {
  const { t } = useTranslation();

  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedStore, setSelectedStore] = useState<Store | null>(null);
  
  // API state
  const [stores, setStores] = useState<Store[]>([]);
  const [pagination, setPagination] = useState<PaginationInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  // Modal state
  const [formModalOpen, setFormModalOpen] = useState(false);
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [editStoreId, setEditStoreId] = useState<string | undefined>(undefined);
  const [viewStoreId, setViewStoreId] = useState<string | null>(null);

  // Fetch stores from API
  const fetchStores = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await storeApi.getStores({
        page: page + 1, // API uses 1-based pagination
        page_size: rowsPerPage,
      });
      setStores(result.items);
      setPagination(result.pagination);
    } catch (err) {
      console.error('Failed to fetch stores:', err);
      setError(err instanceof Error ? err.message : 'Failed to load stores');
    } finally {
      setLoading(false);
    }
  }, [page, rowsPerPage]);

  // Load stores on mount and when pagination changes
  useEffect(() => {
    fetchStores();
  }, [fetchStores]);

  const getStoreTypeColor = (type: string) => {
    const colorKey = storeTypeToColorKey[type as StoreType] || 'mega';
    return storeTypeColors[colorKey];
  };

  const getStoreTypeLabel = (type: string) => {
    return storeTypeLabels[type as StoreType] || type || 'Unknown';
  };

  const getMiniAppTypeLabel = (type: string | undefined) => {
    if (!type) return '-';
    return miniAppTypeLabels[type] || type;
  };

  const columns: Column<Store>[] = [
    {
      id: 'name',
      label: t('stores.storeName'),
      minWidth: 200,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar
            variant="rounded"
            src={row.imageUrl}
            sx={{
              width: 48,
              height: 48,
              bgcolor: alpha(getStoreTypeColor(row.storeType), 0.1),
            }}
          >
            <StoreIcon sx={{ color: getStoreTypeColor(row.storeType) }} />
          </Avatar>
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
      id: 'city',
      label: t('stores.city'),
      minWidth: 100,
    },
    {
      id: 'address',
      label: t('stores.address'),
      minWidth: 200,
      format: (value) => (
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1 }}>
          <LocationIcon fontSize="small" color="action" sx={{ mt: 0.25, flexShrink: 0 }} />
          <Typography variant="body2" color="text.secondary" sx={{ wordBreak: 'break-word' }}>
            {value}
          </Typography>
        </Box>
      ),
    },
    {
      id: 'etwMiniAppType',
      label: t('stores.miniAppType') || 'Mini App',
      minWidth: 80,
      format: (value) => (
        <Chip
          label={getMiniAppTypeLabel(value)}
          size="small"
          variant="outlined"
        />
      ),
    },
    {
      id: 'latitude',
      label: t('stores.latitude') || 'Lat',
      minWidth: 100,
      format: (value) => (
        <Typography variant="body2" fontFamily="monospace" fontSize="0.75rem">
          {value ? Number(value).toFixed(6) : '-'}
        </Typography>
      ),
    },
    {
      id: 'longitude',
      label: t('stores.longitude') || 'Long',
      minWidth: 100,
      format: (value) => (
        <Typography variant="body2" fontFamily="monospace" fontSize="0.75rem">
          {value ? Number(value).toFixed(6) : '-'}
        </Typography>
      ),
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
                setViewStoreId(row.id);
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
                setEditStoreId(row.id);
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

  // Filter stores client-side (for search and type/status filters)
  const filteredStores = stores.filter((store) => {
    const matchesSearch =
      store.name.toLowerCase().includes(search.toLowerCase()) ||
      store.address.toLowerCase().includes(search.toLowerCase()) ||
      store.city.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || store.storeType === typeFilter;
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && store.isActive) ||
      (statusFilter === 'inactive' && !store.isActive);
    return matchesSearch && matchesType && matchesStatus;
  });

  const handleDeleteConfirm = async () => {
    if (!selectedStore) return;
    
    setDeleting(true);
    try {
      await storeApi.deleteStore(selectedStore.id);
      // Refresh the stores list
      await fetchStores();
    } catch (err) {
      console.error('Failed to delete store:', err);
      setError(err instanceof Error ? err.message : 'Failed to delete store');
    } finally {
      setDeleting(false);
      setDeleteDialogOpen(false);
      setSelectedStore(null);
    }
  };

  // Modal handlers
  const handleOpenCreateModal = () => {
    setEditStoreId(undefined);
    setFormModalOpen(true);
  };

  const handleOpenEditModal = (storeId: string) => {
    setEditStoreId(storeId);
    setFormModalOpen(true);
    setDetailModalOpen(false);
  };

  const handleCloseFormModal = () => {
    setFormModalOpen(false);
    setEditStoreId(undefined);
  };

  const handleCloseDetailModal = () => {
    setDetailModalOpen(false);
    setViewStoreId(null);
  };

  const handleFormSuccess = () => {
    fetchStores();
  };

  const actionMenuItems = [
    {
      label: t('stores.create'),
      icon: <AddIcon />,
      onClick: handleOpenCreateModal,
    },
    {
      label: t('common.refresh'),
      icon: <RefreshIcon />,
      onClick: () => fetchStores(),
    },
    {
      label: t('stores.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  // Show loading state
  if (loading && stores.length === 0) {
    return (
      <Box>
        <PageTitle title={t('stores.title')} actions={<ActionMenu actions={actionMenuItems} />} />
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress />
        </Box>
      </Box>
    );
  }

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('stores.title')} actions={<ActionMenu actions={actionMenuItems} />} />

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
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
                { value: 'ETWMega', label: 'MEGA' },
                { value: 'ETWMarket', label: 'MARKET' },
                { value: 'ETWtoGO', label: 'toGO' },
                { value: 'ETWXpress', label: 'XPRESS' },
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
        totalCount={pagination?.total || filteredStores.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('stores.noStores') || 'No stores found'}
        onRowClick={(row) => {
          setViewStoreId(row.id);
          setDetailModalOpen(true);
        }}
        selectable
        loading={loading}
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('stores.deleteTitle') || 'Delete Store'}
        message={
          t('stores.deleteMessage', { name: selectedStore?.name }) ||
          `Are you sure you want to permanently delete "${selectedStore?.name}"? This action cannot be undone.`
        }
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedStore(null);
        }}
        loading={deleting}
      />

      {/* Store Form Modal (Create/Edit) */}
      <StoreFormModal
        open={formModalOpen}
        storeId={editStoreId}
        onClose={handleCloseFormModal}
        onSuccess={handleFormSuccess}
      />

      {/* Store Detail Modal (View) */}
      <StoreDetailModal
        open={detailModalOpen}
        storeId={viewStoreId}
        onClose={handleCloseDetailModal}
        onEdit={handleOpenEditModal}
      />
    </Box>
  );
};

export default StoresPage;
