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
  Avatar,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Category as CategoryIcon,
  Add as AddIcon,
  Upload as UploadIcon,
} from '@mui/icons-material';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, FilterDropdown, type Column } from '@components/common';
import type { Category } from '@/types';

// TODO: DUMMY DATA - Replace with actual API calls
const mockCategories: Category[] = [
  {
    id: '1',
    name: 'Electronics',
    description: 'Electronic devices and accessories',
    productCount: 150,
    imageUrl: 'https://placehold.co/100x100/1976d2/white?text=E',
    isActive: true,
    createdAt: '2023-06-15T10:00:00Z',
    updatedAt: '2024-01-15T14:30:00Z',
  },
  {
    id: '2',
    name: 'Food & Beverage',
    description: 'Food items and drinks',
    productCount: 280,
    imageUrl: 'https://placehold.co/100x100/2e7d32/white?text=F',
    isActive: true,
    createdAt: '2023-07-20T09:00:00Z',
    updatedAt: '2024-01-14T11:20:00Z',
  },
  {
    id: '3',
    name: 'Home & Living',
    description: 'Home decor and furniture',
    productCount: 95,
    imageUrl: 'https://placehold.co/100x100/7b1fa2/white?text=H',
    isActive: true,
    createdAt: '2023-08-10T15:00:00Z',
    updatedAt: '2024-01-15T09:45:00Z',
  },
  {
    id: '4',
    name: 'Fashion',
    description: 'Clothing and apparel',
    productCount: 320,
    imageUrl: 'https://placehold.co/100x100/f9a825/black?text=Fa',
    isActive: true,
    createdAt: '2023-09-05T08:30:00Z',
    updatedAt: '2024-01-15T16:00:00Z',
  },
  {
    id: '5',
    name: 'Health & Beauty',
    description: 'Personal care and cosmetics',
    productCount: 180,
    imageUrl: 'https://placehold.co/100x100/e91e63/white?text=HB',
    isActive: true,
    createdAt: '2023-10-12T11:00:00Z',
    updatedAt: '2024-01-10T13:15:00Z',
  },
  {
    id: '6',
    name: 'Sports & Outdoors',
    description: 'Sports equipment and outdoor gear',
    productCount: 120,
    imageUrl: 'https://placehold.co/100x100/ff5722/white?text=S',
    isActive: false,
    createdAt: '2023-11-01T14:00:00Z',
    updatedAt: '2024-01-08T10:30:00Z',
  },
];

const CategoriesPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const columns: Column<Category>[] = [
    {
      id: 'name',
      label: t('categories.categoryName'),
      minWidth: 250,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar
            variant="rounded"
            src={row.imageUrl}
            sx={{ width: 48, height: 48, bgcolor: 'primary.main' }}
          >
            <CategoryIcon />
          </Avatar>
          <Box>
            <Typography variant="body2" fontWeight={500}>
              {row.name}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {row.description}
            </Typography>
          </Box>
        </Box>
      ),
    },
    {
      id: 'subcategoryCount',
      label: t('categories.subcategories'),
      minWidth: 120,
      align: 'center',
      format: (value) => (
        <Chip
          label={value}
          size="small"
          variant="outlined"
        />
      ),
    },
    {
      id: 'productCount',
      label: t('categories.productCount'),
      minWidth: 100,
      align: 'center',
      format: (value) => value.toLocaleString(),
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
      id: 'updatedAt',
      label: t('common.date'),
      minWidth: 120,
      format: (value) => formatDate(value),
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
                navigate(`/categories/${row.id}`);
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
                navigate(`/categories/${row.id}/edit`);
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
                setSelectedCategory(row);
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

  // Filter categories
  const filteredCategories = mockCategories.filter((category) => {
    const matchesSearch =
      category.name.toLowerCase().includes(search.toLowerCase()) ||
      (category.description?.toLowerCase().includes(search.toLowerCase()) ?? false);
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && category.isActive) ||
      (statusFilter === 'inactive' && !category.isActive);
    return matchesSearch && matchesStatus;
  });

  const handleDeleteConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call delete API
    // TODO: Implement delete category API call for category: ${selectedCategory?.id}
    setDeleteDialogOpen(false);
    setSelectedCategory(null);
  };

  const actionMenuItems = [
    {
      label: t('categories.create'),
      icon: <AddIcon />,
      onClick: () => navigate('/categories/new'),
    },
    {
      label: t('categories.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('categories.title')} actions={<ActionMenu actions={actionMenuItems} />} />

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
              placeholder={t('categories.searchPlaceholder') || 'Search categories...'}
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

      {/* Categories Table */}
      <DataTable
        columns={columns}
        data={filteredCategories}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredCategories.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('categories.noCategories') || 'No categories found'}
        onRowClick={(row) => navigate(`/categories/${row.id}`)}
        selectable
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('categories.deleteTitle') || 'Delete Category'}
        message={t('categories.deleteMessage', { name: selectedCategory?.name }) || `Are you sure you want to delete "${selectedCategory?.name}"?`}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedCategory(null);
        }}
      />

    </Box>
  );
};

export default CategoriesPage;
