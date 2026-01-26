import React, { useState, useCallback, useEffect } from 'react';
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
  CircularProgress,
  Alert,
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
import { categoryApi, type Category } from '@/services/catalogApi';

const CategoriesPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  // State for data
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  // State for filters and pagination
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [totalCount, setTotalCount] = useState(0);

  // State for dialogs
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);

  // Fetch categories from API
  const fetchCategories = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params: Record<string, string | number | boolean | undefined> = {
        page: page + 1, // API uses 1-indexed pages
        page_size: rowsPerPage,
      };

      // Add filters
      if (statusFilter !== 'all') {
        params.is_active = statusFilter === 'active';
      }
      if (search.trim()) {
        params.search = search.trim();
      }

      const response = await categoryApi.getCategories(params);
      setCategories(response.items);
      setTotalCount(response.pagination.totalCount);
    } catch (err) {
      console.error('Failed to fetch categories:', err);
      setError(t('categories.fetchError') || 'Failed to load categories');
    } finally {
      setLoading(false);
    }
  }, [page, rowsPerPage, statusFilter, search, t]);

  // Fetch categories on mount and when filters change
  useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

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

  const handleDeleteConfirm = async () => {
    if (!selectedCategory) return;
    
    setDeleting(true);
    try {
      await categoryApi.deleteCategory(selectedCategory.id);
      setDeleteDialogOpen(false);
      setSelectedCategory(null);
      // Refresh the list
      fetchCategories();
    } catch (err) {
      console.error('Failed to delete category:', err);
      setError(t('categories.deleteError') || 'Failed to delete category');
    } finally {
      setDeleting(false);
    }
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
              placeholder={t('categories.searchPlaceholder') || 'Search categories...'}
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(0); // Reset to first page on search
              }}
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
              onChange={(value) => {
                setStatusFilter(value);
                setPage(0); // Reset to first page on filter change
              }}
              minWidth={180}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Loading State */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        /* Categories Table */
        <DataTable
          columns={columns}
          data={categories}
          page={page}
          rowsPerPage={rowsPerPage}
          totalCount={totalCount}
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
      )}

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
        loading={deleting}
      />

    </Box>
  );
};

export default CategoriesPage;
