import React, { useState, useCallback, useEffect, Fragment } from 'react';
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
  Avatar,
  CircularProgress,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Collapse,
  Paper,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Category as CategoryIcon,
  Add as AddIcon,
  ChevronRight as ChevronRightIcon,
  Folder as SubcategoryIcon,
} from '@mui/icons-material';
import { ConfirmDialog, ActionMenu, PageTitle, FilterDropdown } from '@components/common';
import { categoryApi, storeApi, type Category, type Subcategory, type Store } from '@/services/catalogApi';
import CategoryFormModal from './CategoryFormModal';
import SubcategoryFormModal from './SubcategoryFormModal';

// ETW Store Types from domain/types.go
const ETW_STORE_TYPES = [
  { value: '', label: 'All Store Types' },
  { value: 'ETWMega', label: 'ETW Mega' },
  { value: 'ETWMarket', label: 'ETW Market' },
  { value: 'ETWtoGO', label: 'ETW to GO' },
  { value: 'ETWXpress', label: 'ETW Xpress' },
];

// Color mapping for Store Types
const STORE_TYPE_COLORS: Record<string, string> = {
  'ETWMega': '#0066CC',    // Ocean Blue
  'ETWMarket': '#107C10',  // Forest Green
  'ETWtoGO': '#6A1B9A',    // Imperial Purple
  'ETWXpress': '#FFC107',  // Golden Yellow
};

// Color mapping for Mini-App Types
const MINI_APP_TYPE_COLORS: Record<string, string> = {
  'ETWtoB': '#FF5722',     // Lust Orange
  'ETWtoC': '#65FE08',     // Radioactive Green
  'ETWtoU': '#FFD700',     // Lemon Yellow
  'ETWtoX': '#0437F2',     // Marine Blue
};

// Helper function to get store type chip style
const getStoreTypeStyle = (storeType: string) => ({
  backgroundColor: STORE_TYPE_COLORS[storeType] || undefined,
  color: STORE_TYPE_COLORS[storeType] ? '#fff' : undefined,
  borderColor: STORE_TYPE_COLORS[storeType] || undefined,
});

// Helper function to get mini-app type chip style
const getMiniAppTypeStyle = (miniAppType: string) => ({
  backgroundColor: MINI_APP_TYPE_COLORS[miniAppType] || undefined,
  color: MINI_APP_TYPE_COLORS[miniAppType] 
    ? (['ETWtoC', 'ETWtoU'].includes(miniAppType) ? '#000' : '#fff') 
    : undefined,
  borderColor: MINI_APP_TYPE_COLORS[miniAppType] || undefined,
});

interface ExpandedCategory extends Category {
  subcategories: Subcategory[];
  isExpanded: boolean;
  loadingSubcategories: boolean;
}

const CategoriesPage: React.FC = () => {
  const { t } = useTranslation();

  // State for data
  const [categories, setCategories] = useState<ExpandedCategory[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  const [allStoresMap, setAllStoresMap] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [loadingStores, setLoadingStores] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  // State for filters and pagination
  const [search, setSearch] = useState('');
  const [storeTypeFilter, setStoreTypeFilter] = useState<string>('');
  const [storeFilter, setStoreFilter] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [totalCount, setTotalCount] = useState(0);

  // State for dialogs
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [selectedSubcategory, setSelectedSubcategory] = useState<{ subcategory: Subcategory; category: Category } | null>(null);
  const [deleteType, setDeleteType] = useState<'category' | 'subcategory'>('category');

  // State for modals
  const [categoryModalOpen, setCategoryModalOpen] = useState(false);
  const [editingCategoryId, setEditingCategoryId] = useState<string | undefined>();
  const [subcategoryModalOpen, setSubcategoryModalOpen] = useState(false);
  const [editingSubcategoryId, setEditingSubcategoryId] = useState<string | undefined>();
  const [subcategoryParentCategory, setSubcategoryParentCategory] = useState<{ id: string; name: string } | null>(null);

  // Fetch all stores for lookup (to display store name in table)
  const fetchAllStoresForLookup = useCallback(async () => {
    try {
      const response = await storeApi.getStores({
        page_size: 500, // Fetch enough stores for lookup
      });
      const storesMap: Record<string, string> = {};
      response.items.forEach(store => {
        storesMap[String(store.id)] = store.name;
      });
      setAllStoresMap(storesMap);
    } catch (err) {
      console.error('Failed to fetch stores for lookup:', err);
    }
  }, []);

  // Fetch stores when store type changes
  const fetchStores = useCallback(async (storeType: string) => {
    if (!storeType) {
      setStores([]);
      return;
    }
    
    setLoadingStores(true);
    try {
      const response = await storeApi.getStores({
        etw_store_type: storeType,
        page_size: 100,
        is_active: true,
      });
      setStores(response.items);
    } catch (err) {
      console.error('Failed to fetch stores:', err);
      setStores([]);
    } finally {
      setLoadingStores(false);
    }
  }, []);

  // Fetch categories from API
  const fetchCategories = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params: Record<string, string | number | boolean | undefined> = {
        page: page + 1,
        page_size: rowsPerPage,
      };

      // Add filters
      if (statusFilter !== 'all') {
        params.is_active = statusFilter === 'active';
      }
      if (search.trim()) {
        params.search = search.trim();
      }
      if (storeTypeFilter) {
        params.etw_store_type = storeTypeFilter;
      }
      if (storeFilter) {
        params.store_id = Number(storeFilter);
      }

      const response = await categoryApi.getCategories(params);
      setCategories(response.items.map(cat => ({
        ...cat,
        subcategories: [],
        isExpanded: false,
        loadingSubcategories: false,
      })));
      setTotalCount(response.pagination.total);
    } catch (err) {
      console.error('Failed to fetch categories:', err);
      setError(t('categories.fetchError') || 'Failed to load categories');
    } finally {
      setLoading(false);
    }
  }, [page, rowsPerPage, statusFilter, search, storeTypeFilter, storeFilter, t]);

  // Fetch categories on mount and when filters change
  useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

  // Fetch all stores for lookup on mount
  useEffect(() => {
    fetchAllStoresForLookup();
  }, [fetchAllStoresForLookup]);

  // Handle store type filter change
  const handleStoreTypeChange = (value: string) => {
    setStoreTypeFilter(value);
    setStoreFilter(''); // Reset store filter
    setPage(0);
    if (value) {
      fetchStores(value);
    } else {
      setStores([]);
    }
  };

  // Toggle category expansion to show/hide subcategories
  const toggleExpand = async (categoryId: string) => {
    const categoryIndex = categories.findIndex(c => c.id === categoryId);
    if (categoryIndex === -1) return;

    const category = categories[categoryIndex];
    
    if (category.isExpanded) {
      // Collapse
      setCategories(prev => prev.map(c => 
        c.id === categoryId ? { ...c, isExpanded: false } : c
      ));
    } else {
      // Expand and fetch subcategories if not already loaded
      if (category.subcategories.length === 0) {
        setCategories(prev => prev.map(c => 
          c.id === categoryId ? { ...c, loadingSubcategories: true } : c
        ));
        
        try {
          const subcategories = await categoryApi.getSubcategories(categoryId);
          setCategories(prev => prev.map(c => 
            c.id === categoryId 
              ? { ...c, subcategories, isExpanded: true, loadingSubcategories: false } 
              : c
          ));
        } catch (err) {
          console.error('Failed to fetch subcategories:', err);
          setCategories(prev => prev.map(c => 
            c.id === categoryId ? { ...c, loadingSubcategories: false } : c
          ));
        }
      } else {
        setCategories(prev => prev.map(c => 
          c.id === categoryId ? { ...c, isExpanded: true } : c
        ));
      }
    }
  };

  const formatDateTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  // Handle category deletion
  const handleDeleteCategory = async () => {
    if (!selectedCategory) return;
    
    setDeleting(true);
    try {
      await categoryApi.deleteCategory(selectedCategory.id);
      setDeleteDialogOpen(false);
      setSelectedCategory(null);
      fetchCategories();
    } catch (err) {
      console.error('Failed to delete category:', err);
      setError(t('categories.deleteError') || 'Failed to delete category');
    } finally {
      setDeleting(false);
    }
  };

  // Handle subcategory deletion
  const handleDeleteSubcategory = async () => {
    if (!selectedSubcategory) return;
    
    setDeleting(true);
    try {
      await categoryApi.deleteSubcategory(selectedSubcategory.subcategory.id);
      setDeleteDialogOpen(false);
      
      // Refresh subcategories for the parent category
      const parentId = selectedSubcategory.category.id;
      const subcategories = await categoryApi.getSubcategories(parentId);
      setCategories(prev => prev.map(c => 
        c.id === parentId ? { ...c, subcategories } : c
      ));
      
      setSelectedSubcategory(null);
    } catch (err) {
      console.error('Failed to delete subcategory:', err);
      setError(t('categories.subcategoryDeleteError') || 'Failed to delete subcategory');
    } finally {
      setDeleting(false);
    }
  };

  const handleDeleteConfirm = async () => {
    if (deleteType === 'category') {
      await handleDeleteCategory();
    } else {
      await handleDeleteSubcategory();
    }
  };

  // Open category modal for create
  const openCreateCategoryModal = () => {
    setEditingCategoryId(undefined);
    setCategoryModalOpen(true);
  };

  // Open category modal for edit
  const openEditCategoryModal = (categoryId: string) => {
    setEditingCategoryId(categoryId);
    setCategoryModalOpen(true);
  };

  // Open subcategory modal for create
  const openCreateSubcategoryModal = (category: Category) => {
    setEditingSubcategoryId(undefined);
    setSubcategoryParentCategory({ id: category.id, name: category.name });
    setSubcategoryModalOpen(true);
  };

  // Open subcategory modal for edit
  const openEditSubcategoryModal = (subcategoryId: string, category: Category) => {
    setEditingSubcategoryId(subcategoryId);
    setSubcategoryParentCategory({ id: category.id, name: category.name });
    setSubcategoryModalOpen(true);
  };

  // Handle modal close and success
  const handleCategoryModalSuccess = () => {
    fetchCategories();
  };

  const handleSubcategoryModalSuccess = async () => {
    if (subcategoryParentCategory) {
      // Refresh subcategories for the parent category
      const subcategories = await categoryApi.getSubcategories(subcategoryParentCategory.id);
      setCategories(prev => prev.map(c => 
        c.id === subcategoryParentCategory.id ? { ...c, subcategories, isExpanded: true } : c
      ));
    }
  };

  // Store options for filter dropdown
  const storeOptions = [
    { value: '', label: t('common.allStores') || 'All Stores' },
    ...stores.map(store => ({
      value: store.id,
      label: `${store.name}${store.city ? ` (${store.city})` : ''}`,
    })),
  ];

  const actionMenuItems = [
    {
      label: t('categories.addCategory'),
      icon: <AddIcon />,
      onClick: openCreateCategoryModal,
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
                setPage(0);
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
              label={t('stores.storeType') || 'Store Type'}
              value={storeTypeFilter}
              options={ETW_STORE_TYPES}
              onChange={handleStoreTypeChange}
              minWidth={180}
            />
            <FilterDropdown
              label={t('common.store') || 'Store'}
              value={storeFilter}
              options={storeOptions}
              onChange={(value) => {
                setStoreFilter(value);
                setPage(0);
              }}
              minWidth={200}
              disabled={!storeTypeFilter || loadingStores}
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
                setPage(0);
              }}
              minWidth={150}
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
        /* Categories Table with Expandable Rows */
        <Paper elevation={0}>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell width={50}></TableCell>
                  <TableCell>{t('categories.categoryName')}</TableCell>
                  <TableCell>{t('stores.storeType')}</TableCell>
                  <TableCell>{t('categories.miniAppType') || 'Mini-App Type'}</TableCell>
                  <TableCell>{t('stores.store') || 'Store'}</TableCell>
                  <TableCell align="center">{t('categories.subcategories')}</TableCell>
                  <TableCell align="center">{t('common.status')}</TableCell>
                  <TableCell>{t('common.updatedAt') || 'Updated At'}</TableCell>
                  <TableCell>{t('common.actions')}</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {categories.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={9} align="center" sx={{ py: 4 }}>
                      <Typography color="text.secondary">
                        {t('categories.noCategories') || 'No categories found'}
                      </Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  categories.map((category) => (
                    <Fragment key={category.id}>
                      {/* Category Row */}
                      <TableRow 
                        hover 
                        sx={{ 
                          cursor: 'pointer',
                          '& > *': { borderBottom: category.isExpanded ? 'none' : undefined },
                        }}
                        onClick={() => toggleExpand(category.id)}
                      >
                        <TableCell>
                          <IconButton size="small" onClick={(e) => { e.stopPropagation(); toggleExpand(category.id); }}>
                            {category.loadingSubcategories ? (
                              <CircularProgress size={20} />
                            ) : (
                              <ChevronRightIcon
                                sx={{
                                  transform: category.isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
                                  transition: 'transform 0.2s ease-in-out',
                                }}
                              />
                            )}
                          </IconButton>
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                            <Avatar
                              variant="rounded"
                              src={category.imageUrl}
                              sx={{ width: 48, height: 48, bgcolor: 'primary.main' }}
                            >
                              <CategoryIcon />
                            </Avatar>
                            <Typography variant="body2" fontWeight={500}>
                              {category.name}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          {category.etwStoreType ? (
                            <Chip
                              label={category.etwStoreType}
                              size="small"
                              sx={getStoreTypeStyle(category.etwStoreType)}
                            />
                          ) : (
                            <Typography variant="body2" color="text.secondary">-</Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          {category.etwMiniAppType ? (
                            <Chip
                              label={category.etwMiniAppType}
                              size="small"
                              sx={getMiniAppTypeStyle(category.etwMiniAppType)}
                            />
                          ) : (
                            <Typography variant="body2" color="text.secondary">-</Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          {category.storeId && allStoresMap[category.storeId] ? (
                            <Typography variant="body2">
                              {allStoresMap[category.storeId]}
                            </Typography>
                          ) : (
                            <Typography variant="body2" color="text.secondary">-</Typography>
                          )}
                        </TableCell>
                        <TableCell align="center">
                          <Chip
                            label={category.subcategoryCount ?? 0}
                            size="small"
                            variant="outlined"
                          />
                        </TableCell>
                        <TableCell align="center">
                          <Chip
                            label={category.isActive ? t('common.active') : t('common.inactive')}
                            size="small"
                            color={category.isActive ? 'success' : 'default'}
                          />
                        </TableCell>
                        <TableCell>
                          {category.updatedAt ? formatDateTime(category.updatedAt) : '-'}
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', gap: 0.5 }}>
                            <Tooltip title={t('categories.addSubcategory')}>
                              <IconButton
                                size="small"
                                color="primary"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  openCreateSubcategoryModal(category);
                                }}
                              >
                                <AddIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title={t('common.edit')}>
                              <IconButton
                                size="small"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  openEditCategoryModal(category.id);
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
                                  setDeleteType('category');
                                  setSelectedCategory(category);
                                  setDeleteDialogOpen(true);
                                }}
                              >
                                <DeleteIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                          </Box>
                        </TableCell>
                      </TableRow>

                      {/* Subcategories Collapse Row */}
                      <TableRow>
                        <TableCell colSpan={9} sx={{ py: 0, px: 0 }}>
                          <Collapse in={category.isExpanded} timeout="auto" unmountOnExit>
                            <Box sx={{ pl: 8, pr: 2, py: 2, bgcolor: 'action.hover' }}>
                              {category.subcategories.length === 0 ? (
                                <Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>
                                  {t('categories.noSubcategories') || 'No subcategories'}
                                </Typography>
                              ) : (
                                <Table size="small">
                                  <TableHead>
                                    <TableRow>
                                      <TableCell>{t('categories.subcategoryName') || 'Subcategory'}</TableCell>
                                      <TableCell align="center">{t('common.displayOrder') || 'Order'}</TableCell>
                                      <TableCell align="center">{t('common.status')}</TableCell>
                                      <TableCell>{t('common.updatedAt') || 'Updated At'}</TableCell>
                                      <TableCell>{t('common.actions')}</TableCell>
                                    </TableRow>
                                  </TableHead>
                                  <TableBody>
                                    {category.subcategories.map((subcategory) => (
                                      <TableRow key={subcategory.id} hover>
                                        <TableCell>
                                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                                            <Avatar
                                              variant="rounded"
                                              src={subcategory.imageUrl}
                                              sx={{ width: 32, height: 32, bgcolor: 'secondary.main' }}
                                            >
                                              <SubcategoryIcon fontSize="small" />
                                            </Avatar>
                                            <Typography variant="body2">
                                              {subcategory.name}
                                            </Typography>
                                          </Box>
                                        </TableCell>
                                        <TableCell align="center">
                                          <Typography variant="body2" color="text.secondary">
                                            {subcategory.displayOrder ?? 0}
                                          </Typography>
                                        </TableCell>
                                        <TableCell align="center">
                                          <Chip
                                            label={subcategory.isActive ? t('common.active') : t('common.inactive')}
                                            size="small"
                                            color={subcategory.isActive ? 'success' : 'default'}
                                          />
                                        </TableCell>
                                        <TableCell>
                                          {subcategory.updatedAt ? formatDateTime(subcategory.updatedAt) : '-'}
                                        </TableCell>
                                        <TableCell>
                                          <Box sx={{ display: 'flex', gap: 0.5 }}>
                                            <Tooltip title={t('common.edit')}>
                                              <IconButton
                                                size="small"
                                                onClick={() => openEditSubcategoryModal(subcategory.id, category)}
                                              >
                                                <EditIcon fontSize="small" />
                                              </IconButton>
                                            </Tooltip>
                                            <Tooltip title={t('common.delete')}>
                                              <IconButton
                                                size="small"
                                                color="error"
                                                onClick={() => {
                                                  setDeleteType('subcategory');
                                                  setSelectedSubcategory({ subcategory, category });
                                                  setDeleteDialogOpen(true);
                                                }}
                                              >
                                                <DeleteIcon fontSize="small" />
                                              </IconButton>
                                            </Tooltip>
                                          </Box>
                                        </TableCell>
                                      </TableRow>
                                    ))}
                                  </TableBody>
                                </Table>
                              )}
                            </Box>
                          </Collapse>
                        </TableCell>
                      </TableRow>
                    </Fragment>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
          
          {/* Pagination */}
          <TablePagination
            component="div"
            count={totalCount}
            page={page}
            onPageChange={(_, newPage) => setPage(newPage)}
            rowsPerPage={rowsPerPage}
            onRowsPerPageChange={(e) => {
              setRowsPerPage(parseInt(e.target.value, 10));
              setPage(0);
            }}
            rowsPerPageOptions={[5, 10, 25, 50]}
          />
        </Paper>
      )}

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={
          deleteType === 'category'
            ? (t('categories.deleteTitle') || 'Delete Category')
            : (t('categories.deleteSubcategoryTitle') || 'Delete Subcategory')
        }
        message={
          deleteType === 'category'
            ? (t('categories.deleteMessage', { name: selectedCategory?.name }) || `Are you sure you want to delete "${selectedCategory?.name}"?`)
            : (t('categories.deleteSubcategoryMessage', { name: selectedSubcategory?.subcategory.name }) || `Are you sure you want to delete "${selectedSubcategory?.subcategory.name}"?`)
        }
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedCategory(null);
          setSelectedSubcategory(null);
        }}
        loading={deleting}
      />

      {/* Category Form Modal */}
      <CategoryFormModal
        open={categoryModalOpen}
        categoryId={editingCategoryId}
        preSelectedStoreType={storeTypeFilter}
        preSelectedStoreId={storeFilter}
        onClose={() => {
          setCategoryModalOpen(false);
          setEditingCategoryId(undefined);
        }}
        onSuccess={handleCategoryModalSuccess}
      />

      {/* Subcategory Form Modal */}
      {subcategoryParentCategory && (
        <SubcategoryFormModal
          open={subcategoryModalOpen}
          categoryId={subcategoryParentCategory.id}
          categoryName={subcategoryParentCategory.name}
          subcategoryId={editingSubcategoryId}
          onClose={() => {
            setSubcategoryModalOpen(false);
            setEditingSubcategoryId(undefined);
            setSubcategoryParentCategory(null);
          }}
          onSuccess={handleSubcategoryModalSuccess}
        />
      )}
    </Box>
  );
};

export default CategoriesPage;
