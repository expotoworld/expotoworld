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
  Button,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Category as CategoryIcon,
  Add as AddIcon,
  ChevronRight as ChevronRightIcon,
  Folder as SubcategoryIcon,
  Inventory2 as CollectionIcon,
  DragIndicator as DragIndicatorIcon,
  SwapVert as SwapVertIcon,
} from '@mui/icons-material';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core';
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { ConfirmDialog, ActionMenu, PageTitle, FilterDropdown } from '@components/common';
import { categoryApi, storeApi, type Category, type Subcategory, type Collection, type Subcollection, type Store } from '@/services/catalogApi';
import CategoryFormModal from './CategoryFormModal';
import SubcategoryFormModal from './SubcategoryFormModal';
import CollectionFormModal from './CollectionFormModal';
import SubcollectionFormModal from './SubcollectionFormModal';

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

interface ExpandedCollection extends Collection {
  subcollections: Subcollection[];
  isExpanded: boolean;
  loadingSubcollections: boolean;
}

interface ExpandedSubcategory extends Subcategory {
  collections: ExpandedCollection[];
  isExpanded: boolean;
  loadingCollections: boolean;
}

interface ExpandedCategory extends Category {
  subcategories: ExpandedSubcategory[];
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

  // State for reorder mode
  const [reorderMode, setReorderMode] = useState(false);
  const [reordering, setReordering] = useState(false);

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
  const [deleteType, setDeleteType] = useState<'category' | 'subcategory' | 'collection' | 'subcollection'>('category');

  // State for modals
  const [categoryModalOpen, setCategoryModalOpen] = useState(false);
  const [editingCategoryId, setEditingCategoryId] = useState<string | undefined>();
  const [subcategoryModalOpen, setSubcategoryModalOpen] = useState(false);
  const [editingSubcategoryId, setEditingSubcategoryId] = useState<string | undefined>();
  const [subcategoryParentCategory, setSubcategoryParentCategory] = useState<{ id: string; name: string } | null>(null);

  // State for collection modals & delete
  const [collectionModalOpen, setCollectionModalOpen] = useState(false);
  const [editingCollectionId, setEditingCollectionId] = useState<string | undefined>();
  const [collectionParentSubcategory, setCollectionParentSubcategory] = useState<{ id: string; name: string } | null>(null);
  const [selectedCollection, setSelectedCollection] = useState<{ collection: Collection; subcategory: Subcategory; categoryId: string } | null>(null);

  // State for subcollection modals & delete
  const [subcollectionModalOpen, setSubcollectionModalOpen] = useState(false);
  const [editingSubcollectionId, setEditingSubcollectionId] = useState<string | undefined>();
  const [subcollectionParentCollection, setSubcollectionParentCollection] = useState<{ id: string; name: string; categoryId: string; subcategoryId: string } | null>(null);
  const [selectedSubcollection, setSelectedSubcollection] = useState<{ subcollection: Subcollection; collection: Collection; subcategoryId: string; categoryId: string } | null>(null);

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
          const expandedSubs: ExpandedSubcategory[] = subcategories.map(s => ({
            ...s,
            collections: [],
            isExpanded: false,
            loadingCollections: false,
          }));
          setCategories(prev => prev.map(c => 
            c.id === categoryId 
              ? { ...c, subcategories: expandedSubs, isExpanded: true, loadingSubcategories: false } 
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

  // Toggle subcategory expansion to show/hide collections
  const toggleSubcategoryExpand = async (categoryId: string, subcategoryId: string) => {
    const updateSubcategory = (updater: (sub: ExpandedSubcategory) => ExpandedSubcategory) => {
      setCategories(prev => prev.map(c =>
        c.id === categoryId
          ? { ...c, subcategories: c.subcategories.map(s => s.id === subcategoryId ? updater(s) : s) }
          : c
      ));
    };

    const category = categories.find(c => c.id === categoryId);
    if (!category) return;
    const subcategory = category.subcategories.find(s => s.id === subcategoryId);
    if (!subcategory) return;

    if (subcategory.isExpanded) {
      updateSubcategory(s => ({ ...s, isExpanded: false }));
    } else {
      if (subcategory.collections.length === 0) {
        updateSubcategory(s => ({ ...s, loadingCollections: true }));
        try {
          const collections = await categoryApi.getCollections(subcategoryId);
          const expandedCols: ExpandedCollection[] = collections.map(col => ({
            ...col,
            subcollections: [],
            isExpanded: false,
            loadingSubcollections: false,
          }));
          updateSubcategory(s => ({ ...s, collections: expandedCols, isExpanded: true, loadingCollections: false }));
        } catch (err) {
          console.error('Failed to fetch collections:', err);
          updateSubcategory(s => ({ ...s, loadingCollections: false }));
        }
      } else {
        updateSubcategory(s => ({ ...s, isExpanded: true }));
      }
    }
  };

  // Toggle collection expansion to show/hide subcollections (4th tier)
  const toggleCollectionExpand = async (categoryId: string, subcategoryId: string, collectionId: string) => {
    const updateCollection = (updater: (col: ExpandedCollection) => ExpandedCollection) => {
      setCategories(prev => prev.map(c =>
        c.id === categoryId
          ? {
              ...c,
              subcategories: c.subcategories.map(s =>
                s.id === subcategoryId
                  ? { ...s, collections: s.collections.map(col => col.id === collectionId ? updater(col) : col) }
                  : s
              ),
            }
          : c
      ));
    };

    const category = categories.find(c => c.id === categoryId);
    if (!category) return;
    const subcategory = category.subcategories.find(s => s.id === subcategoryId);
    if (!subcategory) return;
    const collection = subcategory.collections.find(col => col.id === collectionId);
    if (!collection) return;

    if (collection.isExpanded) {
      updateCollection(col => ({ ...col, isExpanded: false }));
    } else {
      if (collection.subcollections.length === 0) {
        updateCollection(col => ({ ...col, loadingSubcollections: true }));
        try {
          const subcollections = await categoryApi.getSubcollections(collectionId);
          updateCollection(col => ({ ...col, subcollections, isExpanded: true, loadingSubcollections: false }));
        } catch (err) {
          console.error('Failed to fetch subcollections:', err);
          updateCollection(col => ({ ...col, loadingSubcollections: false }));
        }
      } else {
        updateCollection(col => ({ ...col, isExpanded: true }));
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
      const expandedSubs: ExpandedSubcategory[] = subcategories.map(s => ({
        ...s,
        collections: [],
        isExpanded: false,
        loadingCollections: false,
      }));
      setCategories(prev => prev.map(c => 
        c.id === parentId ? { ...c, subcategories: expandedSubs } : c
      ));
      
      setSelectedSubcategory(null);
    } catch (err) {
      console.error('Failed to delete subcategory:', err);
      setError(t('categories.subcategoryDeleteError') || 'Failed to delete subcategory');
    } finally {
      setDeleting(false);
    }
  };

  // Handle collection deletion
  const handleDeleteCollection = async () => {
    if (!selectedCollection) return;
    
    setDeleting(true);
    try {
      await categoryApi.deleteCollection(selectedCollection.collection.id);
      setDeleteDialogOpen(false);
      
      // Refresh collections for the parent subcategory
      const parentSubId = selectedCollection.subcategory.id;
      const parentCatId = selectedCollection.categoryId;
      const collections = await categoryApi.getCollections(parentSubId);
      const expandedCollections: ExpandedCollection[] = collections.map(col => ({
        ...col,
        subcollections: [],
        isExpanded: false,
        loadingSubcollections: false,
      }));
      setCategories(prev => prev.map(c =>
        c.id === parentCatId
          ? {
              ...c,
              subcategories: c.subcategories.map(s =>
                s.id === parentSubId ? { ...s, collections: expandedCollections } : s
              ),
            }
          : c
      ));
      
      setSelectedCollection(null);
    } catch (err) {
      console.error('Failed to delete collection:', err);
      setError(t('categories.collectionDeleteError') || 'Failed to delete collection');
    } finally {
      setDeleting(false);
    }
  };

  const handleDeleteConfirm = async () => {
    if (deleteType === 'category') {
      await handleDeleteCategory();
    } else if (deleteType === 'subcategory') {
      await handleDeleteSubcategory();
    } else if (deleteType === 'collection') {
      await handleDeleteCollection();
    } else {
      await handleDeleteSubcollection();
    }
  };

  // Handle subcollection deletion
  const handleDeleteSubcollection = async () => {
    if (!selectedSubcollection) return;

    setDeleting(true);
    try {
      await categoryApi.deleteSubcollection(selectedSubcollection.subcollection.id);
      setDeleteDialogOpen(false);

      // Refresh subcollections for the parent collection
      const parentColId = selectedSubcollection.collection.id;
      const parentSubId = selectedSubcollection.subcategoryId;
      const parentCatId = selectedSubcollection.categoryId;
      const subcollections = await categoryApi.getSubcollections(parentColId);
      setCategories(prev => prev.map(c =>
        c.id === parentCatId
          ? {
              ...c,
              subcategories: c.subcategories.map(s =>
                s.id === parentSubId
                  ? {
                      ...s,
                      collections: s.collections.map(col =>
                        col.id === parentColId ? { ...col, subcollections } : col
                      ),
                    }
                  : s
              ),
            }
          : c
      ));

      setSelectedSubcollection(null);
    } catch (err) {
      console.error('Failed to delete subcollection:', err);
      setError(t('categories.subcollectionDeleteError') || 'Failed to delete subcollection');
    } finally {
      setDeleting(false);
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

  // Open collection modal for create
  const openCreateCollectionModal = (subcategory: Subcategory) => {
    setEditingCollectionId(undefined);
    setCollectionParentSubcategory({ id: subcategory.id, name: subcategory.name });
    setCollectionModalOpen(true);
  };

  // Open collection modal for edit
  const openEditCollectionModal = (collectionId: string, subcategory: Subcategory) => {
    setEditingCollectionId(collectionId);
    setCollectionParentSubcategory({ id: subcategory.id, name: subcategory.name });
    setCollectionModalOpen(true);
  };

  // Handle modal close and success
  const handleCategoryModalSuccess = () => {
    fetchCategories();
  };

  const handleSubcategoryModalSuccess = async () => {
    if (subcategoryParentCategory) {
      // Refresh subcategories for the parent category
      const subcategories = await categoryApi.getSubcategories(subcategoryParentCategory.id);
      const expandedSubs: ExpandedSubcategory[] = subcategories.map(s => ({
        ...s,
        collections: [],
        isExpanded: false,
        loadingCollections: false,
      }));
      setCategories(prev => prev.map(c => 
        c.id === subcategoryParentCategory.id ? { ...c, subcategories: expandedSubs, isExpanded: true } : c
      ));
    }
  };

  const handleCollectionModalSuccess = async () => {
    if (collectionParentSubcategory) {
      // Refresh collections for the parent subcategory
      const collections = await categoryApi.getCollections(collectionParentSubcategory.id);
      const expandedCols: ExpandedCollection[] = collections.map(col => ({
        ...col,
        subcollections: [],
        isExpanded: false,
        loadingSubcollections: false,
      }));
      setCategories(prev => prev.map(c => ({
        ...c,
        subcategories: c.subcategories.map(s =>
          s.id === collectionParentSubcategory.id ? { ...s, collections: expandedCols, isExpanded: true } : s
        ),
      })));
    }
  };

  // Open subcollection modal for create
  const openCreateSubcollectionModal = (collection: Collection, categoryId: string, subcategoryId: string) => {
    setEditingSubcollectionId(undefined);
    setSubcollectionParentCollection({ id: collection.id, name: collection.name, categoryId, subcategoryId });
    setSubcollectionModalOpen(true);
  };

  // Open subcollection modal for edit
  const openEditSubcollectionModal = (subcollectionId: string, collection: Collection, categoryId: string, subcategoryId: string) => {
    setEditingSubcollectionId(subcollectionId);
    setSubcollectionParentCollection({ id: collection.id, name: collection.name, categoryId, subcategoryId });
    setSubcollectionModalOpen(true);
  };

  const handleSubcollectionModalSuccess = async () => {
    if (subcollectionParentCollection) {
      const subcollections = await categoryApi.getSubcollections(subcollectionParentCollection.id);
      setCategories(prev => prev.map(c =>
        c.id === subcollectionParentCollection.categoryId
          ? {
              ...c,
              subcategories: c.subcategories.map(s =>
                s.id === subcollectionParentCollection.subcategoryId
                  ? {
                      ...s,
                      collections: s.collections.map(col =>
                        col.id === subcollectionParentCollection.id
                          ? { ...col, subcollections, isExpanded: true }
                          : col
                      ),
                    }
                  : s
              ),
            }
          : c
      ));
    }
  };

  // ---- Drag-and-Drop Reorder ----
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  const handleCategoryDragEnd = useCallback(async (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const oldIndex = categories.findIndex(c => c.id === String(active.id));
    const newIndex = categories.findIndex(c => c.id === String(over.id));
    if (oldIndex === -1 || newIndex === -1) return;

    const reordered = arrayMove(categories, oldIndex, newIndex);
    setCategories(reordered); // optimistic update

    setReordering(true);
    try {
      await categoryApi.reorderCategories(reordered.map(c => Number(c.id)));
    } catch (err) {
      console.error('Failed to reorder categories:', err);
      setError('Failed to reorder categories');
      fetchCategories(); // rollback
    } finally {
      setReordering(false);
    }
  }, [categories, fetchCategories]);

  const handleSubcategoryDragEnd = useCallback(async (categoryId: string, event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const category = categories.find(c => c.id === categoryId);
    if (!category) return;

    const oldIndex = category.subcategories.findIndex(s => s.id === String(active.id));
    const newIndex = category.subcategories.findIndex(s => s.id === String(over.id));
    if (oldIndex === -1 || newIndex === -1) return;

    const reorderedSubs = arrayMove(category.subcategories, oldIndex, newIndex);
    // Optimistic update
    setCategories(prev => prev.map(c =>
      c.id === categoryId ? { ...c, subcategories: reorderedSubs } : c
    ));

    setReordering(true);
    try {
      await categoryApi.reorderSubcategories(categoryId, reorderedSubs.map(s => Number(s.id)));
    } catch (err) {
      console.error('Failed to reorder subcategories:', err);
      setError('Failed to reorder subcategories');
      // Rollback: re-fetch subcategories
      const refreshed = await categoryApi.getSubcategories(categoryId);
      const expandedRefreshed: ExpandedSubcategory[] = refreshed.map(s => ({
        ...s,
        collections: [],
        isExpanded: false,
        loadingCollections: false,
      }));
      setCategories(prev => prev.map(c =>
        c.id === categoryId ? { ...c, subcategories: expandedRefreshed } : c
      ));
    } finally {
      setReordering(false);
    }
  }, [categories]);

  const handleCollectionDragEnd = useCallback(async (categoryId: string, subcategoryId: string, event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const category = categories.find(c => c.id === categoryId);
    if (!category) return;
    const subcategory = category.subcategories.find(s => s.id === subcategoryId);
    if (!subcategory) return;

    const oldIndex = subcategory.collections.findIndex(col => col.id === String(active.id));
    const newIndex = subcategory.collections.findIndex(col => col.id === String(over.id));
    if (oldIndex === -1 || newIndex === -1) return;

    const reorderedCols = arrayMove(subcategory.collections, oldIndex, newIndex);
    // Optimistic update
    setCategories(prev => prev.map(c =>
      c.id === categoryId
        ? {
            ...c,
            subcategories: c.subcategories.map(s =>
              s.id === subcategoryId ? { ...s, collections: reorderedCols } : s
            ),
          }
        : c
    ));

    setReordering(true);
    try {
      await categoryApi.reorderCollections(subcategoryId, reorderedCols.map(col => Number(col.id)));
    } catch (err) {
      console.error('Failed to reorder collections:', err);
      setError('Failed to reorder collections');
      // Rollback
      const refreshed = await categoryApi.getCollections(subcategoryId);
      const expandedRefreshed: ExpandedCollection[] = refreshed.map(col => ({
        ...col,
        subcollections: [],
        isExpanded: false,
        loadingSubcollections: false,
      }));
      setCategories(prev => prev.map(c =>
        c.id === categoryId
          ? {
              ...c,
              subcategories: c.subcategories.map(s =>
                s.id === subcategoryId ? { ...s, collections: expandedRefreshed } : s
              ),
            }
          : c
      ));
    } finally {
      setReordering(false);
    }
  }, [categories]);

  const handleSubcollectionDragEnd = useCallback(async (categoryId: string, subcategoryId: string, collectionId: string, event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const category = categories.find(c => c.id === categoryId);
    if (!category) return;
    const subcategory = category.subcategories.find(s => s.id === subcategoryId);
    if (!subcategory) return;
    const collection = subcategory.collections.find(col => col.id === collectionId);
    if (!collection) return;

    const oldIndex = collection.subcollections.findIndex(sc => sc.id === String(active.id));
    const newIndex = collection.subcollections.findIndex(sc => sc.id === String(over.id));
    if (oldIndex === -1 || newIndex === -1) return;

    const reorderedSubcols = arrayMove(collection.subcollections, oldIndex, newIndex);
    // Optimistic update
    setCategories(prev => prev.map(c =>
      c.id === categoryId
        ? {
            ...c,
            subcategories: c.subcategories.map(s =>
              s.id === subcategoryId
                ? {
                    ...s,
                    collections: s.collections.map(col =>
                      col.id === collectionId ? { ...col, subcollections: reorderedSubcols } : col
                    ),
                  }
                : s
            ),
          }
        : c
    ));

    setReordering(true);
    try {
      await categoryApi.reorderSubcollections(collectionId, reorderedSubcols.map(sc => Number(sc.id)));
    } catch (err) {
      console.error('Failed to reorder subcollections:', err);
      setError('Failed to reorder subcollections');
      // Rollback
      const refreshed = await categoryApi.getSubcollections(collectionId);
      setCategories(prev => prev.map(c =>
        c.id === categoryId
          ? {
              ...c,
              subcategories: c.subcategories.map(s =>
                s.id === subcategoryId
                  ? {
                      ...s,
                      collections: s.collections.map(col =>
                        col.id === collectionId ? { ...col, subcollections: refreshed } : col
                      ),
                    }
                  : s
              ),
            }
          : c
      ));
    } finally {
      setReordering(false);
    }
  }, [categories]);

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

  // Helper: wraps a render function with a useSortable hook for table row DnD
  const SortableRowProvider = ({ id, children }: {
    id: string | number;
    children: (props: ReturnType<typeof useSortable>) => React.ReactNode;
  }) => {
    const sortableProps = useSortable({ id, disabled: !reorderMode });
    return <>{children(sortableProps)}</>;
  };

  // Sortable subcollection row (4th tier)
  const SortableSubcollectionRow = ({ subcollection, collection, subcategoryId, categoryId }: { subcollection: Subcollection; collection: ExpandedCollection; subcategoryId: string; categoryId: string }) => {
    const {
      attributes,
      listeners,
      setNodeRef,
      transform,
      transition,
      isDragging,
    } = useSortable({ id: subcollection.id });

    return (
      <TableRow
        ref={setNodeRef}
        hover
        style={{
          transform: CSS.Transform.toString(transform),
          transition,
        }}
        sx={{ opacity: isDragging ? 0.5 : 1 }}
      >
        <TableCell>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <IconButton
              size="small"
              sx={{ cursor: 'grab', touchAction: 'none', mr: 0.5 }}
              {...attributes}
              {...listeners}
            >
              <DragIndicatorIcon fontSize="small" color="action" />
            </IconButton>
            <Avatar
              variant="rounded"
              src={subcollection.imageUrl}
              sx={{ width: 24, height: 24, bgcolor: 'warning.main' }}
            >
              <CollectionIcon sx={{ fontSize: 12 }} />
            </Avatar>
            <Typography variant="body2">{subcollection.name}</Typography>
          </Box>
        </TableCell>
        <TableCell align="center">
          <Chip
            label={subcollection.productCount ?? 0}
            size="small"
            variant="outlined"
          />
        </TableCell>
        <TableCell align="center">
          <Typography variant="body2" color="text.secondary">
            {subcollection.displayOrder ?? 0}
          </Typography>
        </TableCell>
        <TableCell align="center">
          <Chip
            label={subcollection.isActive ? t('common.active') : t('common.inactive')}
            size="small"
            color={subcollection.isActive ? 'success' : 'default'}
          />
        </TableCell>
        <TableCell>
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Tooltip title={t('common.edit')}>
              <IconButton size="small" onClick={() => openEditSubcollectionModal(subcollection.id, collection, categoryId, subcategoryId)}>
                <EditIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <Tooltip title={t('common.delete')}>
              <IconButton
                size="small"
                color="error"
                onClick={() => {
                  setDeleteType('subcollection');
                  setSelectedSubcollection({ subcollection, collection, subcategoryId, categoryId });
                  setDeleteDialogOpen(true);
                }}
              >
                <DeleteIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Box>
        </TableCell>
      </TableRow>
    );
  };

  // Sortable collection row (expandable to show subcollections)
  const SortableCollectionRow = ({ collection, subcategory, categoryId }: { collection: ExpandedCollection; subcategory: ExpandedSubcategory; categoryId: string }) => {
    const {
      attributes,
      listeners,
      setNodeRef,
      transform,
      transition,
      isDragging,
    } = useSortable({ id: collection.id });

    return (
      <>
        <TableRow
          ref={setNodeRef}
          hover
          style={{
            transform: CSS.Transform.toString(transform),
            transition,
          }}
          sx={{
            opacity: isDragging ? 0.5 : 1,
            cursor: 'pointer',
            '& > *': { borderBottom: collection.isExpanded ? 'none' : undefined },
          }}
          onClick={() => toggleCollectionExpand(categoryId, subcategory.id, collection.id)}
        >
          <TableCell>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
              <IconButton
                size="small"
                sx={{ cursor: 'grab', touchAction: 'none', mr: 0.5 }}
                onClick={(e) => e.stopPropagation()}
                {...attributes}
                {...listeners}
              >
                <DragIndicatorIcon fontSize="small" color="action" />
              </IconButton>
              <IconButton
                size="small"
                onClick={(e) => { e.stopPropagation(); toggleCollectionExpand(categoryId, subcategory.id, collection.id); }}
              >
                {collection.loadingSubcollections ? (
                  <CircularProgress size={14} />
                ) : (
                  <ChevronRightIcon
                    sx={{
                      fontSize: 16,
                      transform: collection.isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
                      transition: 'transform 0.2s ease-in-out',
                    }}
                  />
                )}
              </IconButton>
              <Avatar
                variant="rounded"
                src={collection.imageUrl}
                sx={{ width: 28, height: 28, bgcolor: 'info.main' }}
              >
                <CollectionIcon sx={{ fontSize: 14 }} />
              </Avatar>
              <Typography variant="body2">{collection.name}</Typography>
            </Box>
          </TableCell>
          <TableCell align="center">
            <Chip
              label={collection.productCount ?? 0}
              size="small"
              variant="outlined"
            />
          </TableCell>
          <TableCell align="center">
            <Typography variant="body2" color="text.secondary">
              {collection.displayOrder ?? 0}
            </Typography>
          </TableCell>
          <TableCell align="center">
            <Chip
              label={collection.isActive ? t('common.active') : t('common.inactive')}
              size="small"
              color={collection.isActive ? 'success' : 'default'}
            />
          </TableCell>
          <TableCell>
            <Box sx={{ display: 'flex', gap: 0.5 }}>
              <Tooltip title={t('categories.addSubcollection') || 'Add Subcollection'}>
                <IconButton
                  size="small"
                  color="primary"
                  onClick={(e) => {
                    e.stopPropagation();
                    openCreateSubcollectionModal(collection, categoryId, subcategory.id);
                  }}
                >
                  <AddIcon fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title={t('common.edit')}>
                <IconButton size="small" onClick={(e) => { e.stopPropagation(); openEditCollectionModal(collection.id, subcategory); }}>
                  <EditIcon fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title={t('common.delete')}>
                <IconButton
                  size="small"
                  color="error"
                  onClick={(e) => {
                    e.stopPropagation();
                    setDeleteType('collection');
                    setSelectedCollection({ collection, subcategory, categoryId });
                    setDeleteDialogOpen(true);
                  }}
                >
                  <DeleteIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </Box>
          </TableCell>
        </TableRow>

        {/* Subcollections Collapse Row (4th tier) */}
        <TableRow>
          <TableCell colSpan={5} sx={{ py: 0, px: 0 }}>
            <Collapse in={collection.isExpanded} timeout="auto" unmountOnExit>
              <Box sx={{ pl: 6, pr: 2, py: 1.5, bgcolor: 'action.focus', borderRadius: 1 }}>
                {collection.subcollections.length === 0 ? (
                  <Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>
                    {t('categories.noSubcollections') || 'No subcollections'}
                  </Typography>
                ) : (
                  <DndContext
                    sensors={sensors}
                    collisionDetection={closestCenter}
                    onDragEnd={(event) => handleSubcollectionDragEnd(categoryId, subcategory.id, collection.id, event)}
                  >
                    <SortableContext
                      items={collection.subcollections.map(sc => sc.id)}
                      strategy={verticalListSortingStrategy}
                    >
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            <TableCell>{t('categories.subcollectionName') || 'Subcollection'}</TableCell>
                            <TableCell align="center">{t('categories.products') || 'Products'}</TableCell>
                            <TableCell align="center">{t('common.displayOrder') || 'Order'}</TableCell>
                            <TableCell align="center">{t('common.status')}</TableCell>
                            <TableCell>{t('common.actions')}</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {collection.subcollections.map((subcollection) => (
                            <SortableSubcollectionRow
                              key={subcollection.id}
                              subcollection={subcollection}
                              collection={collection}
                              subcategoryId={subcategory.id}
                              categoryId={categoryId}
                            />
                          ))}
                        </TableBody>
                      </Table>
                    </SortableContext>
                  </DndContext>
                )}
              </Box>
            </Collapse>
          </TableCell>
        </TableRow>
      </>
    );
  };

  // Stand-alone sortable subcategory row (uses useSortable internally)
  const SortableSubcategoryRow = ({ subcategory, category }: { subcategory: ExpandedSubcategory; category: ExpandedCategory }) => {
    const {
      attributes,
      listeners,
      setNodeRef,
      transform,
      transition,
      isDragging,
    } = useSortable({ id: subcategory.id });

    return (
      <>
        <TableRow
          ref={setNodeRef}
          hover
          style={{
            transform: CSS.Transform.toString(transform),
            transition,
          }}
          sx={{
            opacity: isDragging ? 0.5 : 1,
            cursor: 'pointer',
            '& > *': { borderBottom: subcategory.isExpanded ? 'none' : undefined },
          }}
          onClick={() => toggleSubcategoryExpand(category.id, subcategory.id)}
        >
          <TableCell>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
              <IconButton
                size="small"
                sx={{ cursor: 'grab', touchAction: 'none', mr: 0.5 }}
                onClick={(e) => e.stopPropagation()}
                {...attributes}
                {...listeners}
              >
                <DragIndicatorIcon fontSize="small" color="action" />
              </IconButton>
              <IconButton
                size="small"
                onClick={(e) => { e.stopPropagation(); toggleSubcategoryExpand(category.id, subcategory.id); }}
              >
                {subcategory.loadingCollections ? (
                  <CircularProgress size={16} />
                ) : (
                  <ChevronRightIcon
                    sx={{
                      fontSize: 18,
                      transform: subcategory.isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
                      transition: 'transform 0.2s ease-in-out',
                    }}
                  />
                )}
              </IconButton>
              <Avatar
                variant="rounded"
                src={subcategory.imageUrl}
                sx={{ width: 32, height: 32, bgcolor: 'secondary.main' }}
              >
                <SubcategoryIcon fontSize="small" />
              </Avatar>
              <Typography variant="body2">{subcategory.name}</Typography>
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
              <Tooltip title={t('categories.addCollection') || 'Add Collection'}>
                <IconButton
                  size="small"
                  color="primary"
                  onClick={(e) => {
                    e.stopPropagation();
                    openCreateCollectionModal(subcategory);
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
                    openEditSubcategoryModal(subcategory.id, category);
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

        {/* Collections Collapse Row (3rd tier) */}
        <TableRow>
          <TableCell colSpan={5} sx={{ py: 0, px: 0 }}>
            <Collapse in={subcategory.isExpanded} timeout="auto" unmountOnExit>
              <Box sx={{ pl: 6, pr: 2, py: 1.5, bgcolor: 'action.selected', borderRadius: 1 }}>
                {subcategory.collections.length === 0 ? (
                  <Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>
                    {t('categories.noCollections') || 'No collections'}
                  </Typography>
                ) : (
                  <DndContext
                    sensors={sensors}
                    collisionDetection={closestCenter}
                    onDragEnd={(event) => handleCollectionDragEnd(category.id, subcategory.id, event)}
                  >
                    <SortableContext
                      items={subcategory.collections.map(col => col.id)}
                      strategy={verticalListSortingStrategy}
                    >
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            <TableCell>{t('categories.collectionName') || 'Collection'}</TableCell>
                            <TableCell align="center">{t('categories.products') || 'Products'}</TableCell>
                            <TableCell align="center">{t('common.displayOrder') || 'Order'}</TableCell>
                            <TableCell align="center">{t('common.status')}</TableCell>
                            <TableCell>{t('common.actions')}</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {subcategory.collections.map((collection) => (
                            <SortableCollectionRow
                              key={collection.id}
                              collection={collection}
                              subcategory={subcategory}
                              categoryId={category.id}
                            />
                          ))}
                        </TableBody>
                      </Table>
                    </SortableContext>
                  </DndContext>
                )}
              </Box>
            </Collapse>
          </TableCell>
        </TableRow>
      </>
    );
  };

  return (
    <Box>
      {/* Page Title */}
      <PageTitle
        title={t('categories.title')}
        actions={
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
            <Button
              variant={reorderMode ? 'contained' : 'outlined'}
              size="small"
              startIcon={<SwapVertIcon />}
              onClick={() => setReorderMode(!reorderMode)}
              disabled={reordering}
              color={reorderMode ? 'warning' : 'inherit'}
            >
              {reorderMode ? 'Done Reordering' : 'Reorder'}
            </Button>
            <ActionMenu actions={actionMenuItems} />
          </Box>
        }
      />

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
                  <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleCategoryDragEnd}>
                    <SortableContext
                      items={categories.map(c => c.id)}
                      strategy={verticalListSortingStrategy}
                      disabled={!reorderMode}
                    >
                      {categories.map((category) => (
                        <SortableRowProvider key={category.id} id={category.id}>
                          {({ attributes, listeners, setNodeRef, transform, transition, isDragging }) => (
                            <Fragment>
                              {/* Category Row */}
                              <TableRow
                                ref={setNodeRef}
                                hover
                                style={reorderMode ? {
                                  transform: CSS.Transform.toString(transform),
                                  transition,
                                } : undefined}
                                sx={{
                                  cursor: reorderMode ? 'grab' : 'pointer',
                                  '& > *': { borderBottom: !reorderMode && category.isExpanded ? 'none' : undefined },
                                  opacity: isDragging ? 0.5 : 1,
                                }}
                                onClick={() => !reorderMode && toggleExpand(category.id)}
                              >
                                <TableCell>
                                  {reorderMode ? (
                                    <IconButton
                                      size="small"
                                      sx={{ cursor: 'grab', touchAction: 'none' }}
                                      {...attributes}
                                      {...listeners}
                                    >
                                      <DragIndicatorIcon />
                                    </IconButton>
                                  ) : (
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
                                  )}
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
                                  {!reorderMode && (
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
                                  )}
                                </TableCell>
                              </TableRow>

                              {/* Subcategories Collapse Row - hidden in reorder mode */}
                              {!reorderMode && (
                                <TableRow>
                                  <TableCell colSpan={9} sx={{ py: 0, px: 0 }}>
                                    <Collapse in={category.isExpanded} timeout="auto" unmountOnExit>
                                      <Box sx={{ pl: 8, pr: 2, py: 2, bgcolor: 'action.hover' }}>
                                        {category.subcategories.length === 0 ? (
                                          <Typography variant="body2" color="text.secondary" sx={{ py: 1 }}>
                                            {t('categories.noSubcategories') || 'No subcategories'}
                                          </Typography>
                                        ) : (
                                          <DndContext
                                            sensors={sensors}
                                            collisionDetection={closestCenter}
                                            onDragEnd={(event) => handleSubcategoryDragEnd(category.id, event)}
                                          >
                                            <SortableContext
                                              items={category.subcategories.map(s => s.id)}
                                              strategy={verticalListSortingStrategy}
                                            >
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
                                                    <SortableSubcategoryRow
                                                      key={subcategory.id}
                                                      subcategory={subcategory}
                                                      category={category}
                                                    />
                                                  ))}
                                                </TableBody>
                                              </Table>
                                            </SortableContext>
                                          </DndContext>
                                        )}
                                      </Box>
                                    </Collapse>
                                  </TableCell>
                                </TableRow>
                              )}
                            </Fragment>
                          )}
                        </SortableRowProvider>
                      ))}
                    </SortableContext>
                  </DndContext>
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
            : deleteType === 'subcategory'
              ? (t('categories.deleteSubcategoryTitle') || 'Delete Subcategory')
              : deleteType === 'collection'
                ? (t('categories.deleteCollectionTitle') || 'Delete Collection')
                : (t('categories.deleteSubcollectionTitle') || 'Delete Subcollection')
        }
        message={
          deleteType === 'category'
            ? (t('categories.deleteMessage', { name: selectedCategory?.name }) || `Are you sure you want to delete "${selectedCategory?.name}"?`)
            : deleteType === 'subcategory'
              ? (t('categories.deleteSubcategoryMessage', { name: selectedSubcategory?.subcategory.name }) || `Are you sure you want to delete "${selectedSubcategory?.subcategory.name}"?`)
              : deleteType === 'collection'
                ? (t('categories.deleteCollectionMessage', { name: selectedCollection?.collection.name }) || `Are you sure you want to delete "${selectedCollection?.collection.name}"?`)
                : (t('categories.deleteSubcollectionMessage', { name: selectedSubcollection?.subcollection.name }) || `Are you sure you want to delete "${selectedSubcollection?.subcollection.name}"?`)
        }
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedCategory(null);
          setSelectedSubcategory(null);
          setSelectedCollection(null);
          setSelectedSubcollection(null);
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

      {/* Collection Form Modal */}
      {collectionParentSubcategory && (
        <CollectionFormModal
          open={collectionModalOpen}
          subcategoryId={collectionParentSubcategory.id}
          subcategoryName={collectionParentSubcategory.name}
          collectionId={editingCollectionId}
          onClose={() => {
            setCollectionModalOpen(false);
            setEditingCollectionId(undefined);
            setCollectionParentSubcategory(null);
          }}
          onSuccess={handleCollectionModalSuccess}
        />
      )}

      {/* Subcollection Form Modal */}
      {subcollectionParentCollection && (
        <SubcollectionFormModal
          open={subcollectionModalOpen}
          collectionId={subcollectionParentCollection.id}
          collectionName={subcollectionParentCollection.name}
          subcollectionId={editingSubcollectionId}
          onClose={() => {
            setSubcollectionModalOpen(false);
            setEditingSubcollectionId(undefined);
            setSubcollectionParentCollection(null);
          }}
          onSuccess={handleSubcollectionModalSuccess}
        />
      )}
    </Box>
  );
};

export default CategoriesPage;
