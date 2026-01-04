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
  Switch,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  Upload as UploadIcon,
} from '@mui/icons-material';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, FilterDropdown, type Column } from '@components/common';
import type { Banner } from '@/types';

// TODO: DUMMY DATA - Replace with actual API calls
const mockBanners: Banner[] = [
  {
    id: 'banner-1',
    title: 'Summer Sale 2024',
    subtitle: 'Up to 50% off on selected items',
    imageUrl: 'https://picsum.photos/seed/banner1/800/300',
    linkUrl: '/promotions/summer-sale',
    isActive: true,
    startDate: '2024-06-01T00:00:00Z',
    endDate: '2024-08-31T23:59:59Z',
    position: 1,
    createdAt: '2024-05-15T10:00:00Z',
    updatedAt: '2024-05-20T14:30:00Z',
  },
  {
    id: 'banner-2',
    title: 'New Arrivals',
    subtitle: 'Check out our latest products',
    imageUrl: 'https://picsum.photos/seed/banner2/800/300',
    linkUrl: '/products?filter=new',
    isActive: true,
    startDate: '2024-01-01T00:00:00Z',
    endDate: '2024-12-31T23:59:59Z',
    position: 2,
    createdAt: '2024-01-01T10:00:00Z',
    updatedAt: '2024-01-10T08:00:00Z',
  },
  {
    id: 'banner-3',
    title: 'Free Shipping',
    subtitle: 'On orders over $50',
    imageUrl: 'https://picsum.photos/seed/banner3/800/300',
    linkUrl: '/shipping-info',
    isActive: false,
    startDate: '2024-01-01T00:00:00Z',
    endDate: '2024-12-31T23:59:59Z',
    position: 3,
    createdAt: '2024-01-01T10:00:00Z',
    updatedAt: '2024-03-15T12:00:00Z',
  },
  {
    id: 'banner-4',
    title: 'Holiday Special',
    subtitle: 'Exclusive deals for the holiday season',
    imageUrl: 'https://picsum.photos/seed/banner4/800/300',
    linkUrl: '/promotions/holiday',
    isActive: true,
    startDate: '2024-12-01T00:00:00Z',
    endDate: '2024-12-31T23:59:59Z',
    position: 4,
    createdAt: '2024-11-15T10:00:00Z',
    updatedAt: '2024-11-20T14:30:00Z',
  },
  {
    id: 'banner-5',
    title: 'Membership Rewards',
    subtitle: 'Earn double points this month',
    imageUrl: 'https://picsum.photos/seed/banner5/800/300',
    linkUrl: '/membership',
    isActive: false,
    startDate: '2024-01-01T00:00:00Z',
    endDate: '2024-01-31T23:59:59Z',
    position: 5,
    createdAt: '2023-12-20T10:00:00Z',
    updatedAt: '2024-01-02T08:00:00Z',
  },
];

const ContentPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedBanner, setSelectedBanner] = useState<Banner | null>(null);

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const columns: Column<Banner>[] = [
    {
      id: 'title',
      label: t('content.banner') || 'Banner',
      minWidth: 300,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Box
            component="img"
            src={row.imageUrl}
            alt={row.title}
            sx={{
              width: 80,
              height: 45,
              borderRadius: 1,
              objectFit: 'cover',
            }}
          />
          <Box>
            <Typography variant="body2" fontWeight={500}>
              {row.title}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {row.subtitle}
            </Typography>
          </Box>
        </Box>
      ),
    },
    {
      id: 'position',
      label: t('content.position') || 'Position',
      minWidth: 80,
      align: 'center',
      format: (value) => (
        <Chip label={`#${value}`} size="small" variant="outlined" />
      ),
    },
    {
      id: 'startDate',
      label: t('content.dateRange') || 'Date Range',
      minWidth: 180,
      format: (_, row) => (
        <Typography variant="body2">
          {formatDate(row.startDate || '')} - {formatDate(row.endDate || '')}
        </Typography>
      ),
    },
    {
      id: 'isActive',
      label: t('common.status'),
      minWidth: 120,
      format: (value, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Switch
            checked={value}
            size="small"
            onClick={(e) => e.stopPropagation()}
            onChange={() => {
              // TODO: NEED TO FULLY IMPLEMENT - Toggle banner status
              console.log('Toggle status for banner:', row.id);
            }}
          />
          <Chip
            label={value ? t('common.active') : t('common.inactive')}
            size="small"
            color={value ? 'success' : 'default'}
          />
        </Box>
      ),
    },
    {
      id: 'updatedAt',
      label: t('common.date'),
      minWidth: 120,
      format: (value) => formatDate(value),
    },
    {
      id: 'actions',
      label: t('common.actions'),
      minWidth: 100,
      format: (_, row) => (
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Tooltip title={t('common.edit')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                navigate(`/content/banners/${row.id}/edit`);
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
                setSelectedBanner(row);
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

  // Filter banners
  const filteredBanners = mockBanners.filter((banner) => {
    const matchesSearch =
      banner.title.toLowerCase().includes(search.toLowerCase()) ||
      (banner.subtitle?.toLowerCase().includes(search.toLowerCase()) ?? false);
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && banner.isActive) ||
      (statusFilter === 'inactive' && !banner.isActive);
    return matchesSearch && matchesStatus;
  });

  const handleDeleteConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call delete API
    // TODO: Implement delete banner API call for banner: ${selectedBanner?.id}
    setDeleteDialogOpen(false);
    setSelectedBanner(null);
  };

  const actionMenuItems = [
    {
      label: t('content.create'),
      icon: <AddIcon />,
      onClick: () => navigate('/content/banners/new'),
    },
    {
      label: t('content.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('content.title')} actions={<ActionMenu actions={actionMenuItems} />} />

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
              placeholder={t('content.searchBanners') || 'Search banners...'}
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

      {/* Banners Table */}
      <DataTable
        columns={columns}
        data={filteredBanners}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredBanners.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('content.noBanners') || 'No banners found'}
        onRowClick={(row) => navigate(`/content/banners/${row.id}`)}
        selectable
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('content.deleteConfirmTitle') || 'Delete Banner'}
        message={t('content.deleteConfirmMessage', { name: selectedBanner?.title }) || `Are you sure you want to delete "${selectedBanner?.title}"?`}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedBanner(null);
        }}
      />

    </Box>
  );
};

export default ContentPage;
