import React, { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Grid,
  Typography,
  IconButton,
  CircularProgress,
  Alert,
  InputAdornment,
  Chip,
} from '@mui/material';
import {
  Save as SaveIcon,
  ArrowBack as BackIcon,
  Add as AddIcon,
  Delete as DeleteIcon,
  DragIndicator as DragIcon,
  Image as ImageIcon,
  Close as CloseIcon,
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
  rectSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { PageHeader } from '@components/common';
import {
  productApi,
  categoryApi,
  storeApi,
  type Category,
  type Subcategory,
  type Collection,
  type Subcollection,
  type Store,
  type CreateProductData,
} from '@/services/catalogApi';

interface FormData {
  sku: string;
  title: string;
  description: string;
  storeId: string;
  ownerOrgId: string;
  mainPrice: string;
  strikethroughPrice: string;
  costPrice: string;
  stockLeft: string;
  minimumOrderQuantity: string;
  weight: string;
  shelfCode: string;
  isActive: boolean;
  isFeatured: boolean;
  isMiniAppRecommendation: boolean;
  productType: 'standard' | 'parent' | 'child';
  visibility: 'visible' | 'not_visible';
  etwStoreType: string;
  etwMiniAppType: string;
  categoryIds: number[];
  subcategoryIds: number[];
  collectionIds: number[];
  subcollectionIds: number[];
}

interface AttributeFormData {
  attributeName: string;
  attributeValue: string;
  displayOrder: number;
  isVariantDefining: boolean;
}

interface ImageFormData {
  id: string; // actual DB id for existing images, temp UUID for new ones
  imageUrl: string;
  displayOrder: number;
  isPrimary: boolean;
}

const initialFormData: FormData = {
  sku: '',
  title: '',
  description: '',
  storeId: '',
  ownerOrgId: '',
  mainPrice: '',
  strikethroughPrice: '',
  costPrice: '',
  stockLeft: '0',
  minimumOrderQuantity: '1',
  weight: '1.00',
  shelfCode: '',
  isActive: true,
  isFeatured: false,
  isMiniAppRecommendation: false,
  productType: 'standard',
  visibility: 'visible',
  etwStoreType: '',
  etwMiniAppType: '',
  categoryIds: [],
  subcategoryIds: [],
  collectionIds: [],
  subcollectionIds: [],
};

const ProductFormPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const isEditing = Boolean(id && id !== 'new');

  // Form state
  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [attributes, setAttributes] = useState<AttributeFormData[]>([]);
  const [images, setImages] = useState<ImageFormData[]>([]);

  // Reference data
  const [categories, setCategories] = useState<Category[]>([]);
  const [subcategories, setSubcategories] = useState<Subcategory[]>([]);
  const [collections, setCollections] = useState<Collection[]>([]);
  const [subcollections, setSubcollections] = useState<Subcollection[]>([]);
  const [stores, setStores] = useState<Store[]>([]);

  // UI state
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Fetch reference data
  const fetchReferenceData = useCallback(async () => {
    try {
      const [categoriesRes, storesRes] = await Promise.all([
        categoryApi.getCategories({ page_size: 100 }),
        storeApi.getStores({ page_size: 100 }),
      ]);
      setCategories(categoriesRes.items);
      setStores(storesRes.items);
    } catch (err) {
      console.error('Failed to fetch reference data:', err);
    }
  }, []);

  // Fetch subcategories when category changes
  const fetchSubcategories = useCallback(async (categoryId: string) => {
    if (!categoryId) {
      setSubcategories([]);
      return;
    }
    try {
      const subcatsRes = await categoryApi.getSubcategories(categoryId);
      setSubcategories(subcatsRes);
    } catch (err) {
      console.error('Failed to fetch subcategories:', err);
      setSubcategories([]);
    }
  }, []);

  // Fetch collections when subcategory changes
  const fetchCollections = useCallback(async (subcategoryId: string) => {
    if (!subcategoryId) {
      setCollections([]);
      return;
    }
    try {
      const collectionsRes = await categoryApi.getCollections(subcategoryId);
      setCollections(collectionsRes);
    } catch (err) {
      console.error('Failed to fetch collections:', err);
      setCollections([]);
    }
  }, []);

  // Fetch subcollections when collection changes
  const fetchSubcollections = useCallback(async (collectionId: string) => {
    if (!collectionId) {
      setSubcollections([]);
      return;
    }
    try {
      const subcollectionsRes = await categoryApi.getSubcollections(collectionId);
      setSubcollections(subcollectionsRes);
    } catch (err) {
      console.error('Failed to fetch subcollections:', err);
      setSubcollections([]);
    }
  }, []);

  // Fetch product data if editing
  const fetchProduct = useCallback(async () => {
    if (!isEditing || !id) return;

    setLoading(true);
    setError(null);
    try {
      const product = await productApi.getProduct(id);
      
      // Map product to form data
      setFormData({
        sku: product.sku || '',
        title: product.name,
        description: product.description,
        storeId: product.storeId,
        ownerOrgId: product.organizationId || '',
        mainPrice: String(product.currentPrice),
        strikethroughPrice: product.originalPrice !== product.currentPrice ? String(product.originalPrice) : '',
        costPrice: product.costPrice ? String(product.costPrice) : '',
        stockLeft: String(product.stockLeft),
        minimumOrderQuantity: String(product.minimumOrderQuantity),
        weight: product.logisticsWeight ? String(product.logisticsWeight) : '1.00',
        shelfCode: product.shelfCode,
        isActive: product.isActive,
        isFeatured: product.isFeatured,
        isMiniAppRecommendation: product.isMiniAppRecommendation || false,
        productType: (product.productType as 'standard' | 'parent' | 'child') || 'standard',
        visibility: (product.visibility as 'visible' | 'not_visible') || 'visible',
        etwStoreType: product.etwStoreType || '',
        etwMiniAppType: product.etwMiniAppType || '',
        categoryIds: product.categoryIds || [],
        subcategoryIds: product.subcategoryIds || [],
        collectionIds: product.collectionIds || [],
        subcollectionIds: product.subcollectionIds || [],
      });

      // Map attributes
      if (product.attributes) {
        setAttributes(product.attributes.map((attr) => ({
          attributeName: attr.attributeName,
          attributeValue: attr.attributeValue,
          displayOrder: attr.displayOrder,
          isVariantDefining: attr.isVariantDefining || false,
        })));
      }

      // Map images
      if (product.images) {
        setImages(product.images.map((img) => ({
          id: img.id,
          imageUrl: img.imageUrl,
          displayOrder: img.displayOrder,
          isPrimary: img.isPrimary,
        })));
      }

      // Fetch subcategories for the selected category
      if (product.categoryIds && product.categoryIds.length > 0) {
        fetchSubcategories(String(product.categoryIds[0]));
      }
      // Fetch collections for the selected subcategory
      if (product.subcategoryIds && product.subcategoryIds.length > 0) {
        fetchCollections(String(product.subcategoryIds[0]));
      }
      // Fetch subcollections for the selected collection
      if (product.collectionIds && product.collectionIds.length > 0) {
        fetchSubcollections(String(product.collectionIds[0]));
      }
    } catch (err) {
      console.error('Failed to fetch product:', err);
      setError(t('products.fetchError'));
    } finally {
      setLoading(false);
    }
  }, [id, isEditing, t, fetchSubcategories, fetchCollections, fetchSubcollections]);

  useEffect(() => {
    fetchReferenceData();
  }, [fetchReferenceData]);

  useEffect(() => {
    fetchProduct();
  }, [fetchProduct]);

  // Handle form field changes
  const handleChange = (field: keyof FormData, value: unknown) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  // Handle category change
  const handleCategoryChange = (categoryId: number) => {
    setFormData((prev) => ({
      ...prev,
      categoryIds: categoryId ? [categoryId] : [],
      subcategoryIds: [],
      collectionIds: [],
      subcollectionIds: [],
    }));
    setCollections([]);
    setSubcollections([]);
    fetchSubcategories(String(categoryId));
  };

  // Handle subcategory change
  const handleSubcategoryChange = (subcategoryId: number) => {
    setFormData((prev) => ({
      ...prev,
      subcategoryIds: subcategoryId ? [subcategoryId] : [],
      collectionIds: [],
      subcollectionIds: [],
    }));
    setSubcollections([]);
    fetchCollections(String(subcategoryId));
  };

  // Handle collection change
  const handleCollectionChange = (collectionId: number) => {
    setFormData((prev) => ({
      ...prev,
      collectionIds: collectionId ? [collectionId] : [],
      subcollectionIds: [],
    }));
    fetchSubcollections(String(collectionId));
  };

  // Attribute management
  const addAttribute = () => {
    setAttributes((prev) => [...prev, {
      attributeName: '',
      attributeValue: '',
      displayOrder: prev.length,
      isVariantDefining: false,
    }]);
  };

  const updateAttribute = (index: number, field: keyof AttributeFormData, value: unknown) => {
    setAttributes((prev) => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [field]: value };
      return updated;
    });
  };

  const removeAttribute = (index: number) => {
    setAttributes((prev) => prev.filter((_, i) => i !== index));
  };

  // Image management
  const addImage = () => {
    setImages((prev) => [...prev, {
      id: `temp-${crypto.randomUUID()}`,
      imageUrl: '',
      displayOrder: prev.length,
      isPrimary: prev.length === 0, // First image is primary by default
    }]);
  };

  const updateImage = (index: number, field: keyof ImageFormData, value: unknown) => {
    setImages((prev) => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [field]: value };
      // If setting this as primary, unset others
      if (field === 'isPrimary' && value === true) {
        return updated.map((img, i) => ({
          ...img,
          isPrimary: i === index,
        }));
      }
      return updated;
    });
  };

  const removeImage = (index: number) => {
    setImages((prev) => {
      const filtered = prev.filter((_, i) => i !== index);
      // If we removed the primary image, make the first one primary
      if (prev[index]?.isPrimary && filtered.length > 0) {
        filtered[0].isPrimary = true;
      }
      return filtered;
    });
  };

  // Image drag-and-drop reorder
  const imageSensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  const handleImageDragEnd = useCallback((event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    setImages((prev) => {
      const oldIndex = prev.findIndex(img => img.id === active.id);
      const newIndex = prev.findIndex(img => img.id === over.id);
      if (oldIndex === -1 || newIndex === -1) return prev;
      return arrayMove(prev, oldIndex, newIndex).map((img, i) => ({
        ...img,
        displayOrder: i,
      }));
    });
  }, []);

  // Sortable image card component (inner, has access to closure)
  const SortableImageCard = ({ img, index }: { img: ImageFormData; index: number }) => {
    const {
      attributes,
      listeners,
      setNodeRef,
      transform,
      transition,
      isDragging,
    } = useSortable({ id: img.id });

    return (
      <Grid
        item
        xs={12}
        sm={6}
        md={4}
        ref={setNodeRef}
        style={{
          transform: CSS.Transform.toString(transform),
          transition,
        }}
        sx={{ opacity: isDragging ? 0.5 : 1 }}
      >
        <Box
          sx={{
            border: '1px solid',
            borderColor: img.isPrimary ? 'primary.main' : 'divider',
            borderRadius: 1,
            p: 2,
            position: 'relative',
          }}
        >
          {/* Drag handle */}
          <IconButton
            size="small"
            sx={{
              position: 'absolute',
              top: 4,
              left: 4,
              cursor: 'grab',
              touchAction: 'none',
              zIndex: 2,
            }}
            {...attributes}
            {...listeners}
          >
            <DragIcon fontSize="small" color="action" />
          </IconButton>
          {img.isPrimary && (
            <Chip
              label={t('products.form.primary')}
              size="small"
              color="primary"
              sx={{ position: 'absolute', top: 8, left: 40 }}
            />
          )}
          <IconButton
            size="small"
            sx={{ position: 'absolute', top: 4, right: 4, zIndex: 2 }}
            onClick={() => removeImage(index)}
          >
            <CloseIcon fontSize="small" />
          </IconButton>
          <Box
            sx={{
              width: '100%',
              aspectRatio: '1',
              bgcolor: 'action.hover',
              borderRadius: 1,
              mb: 2,
              mt: 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              overflow: 'hidden',
            }}
          >
            {img.imageUrl ? (
              <img
                src={img.imageUrl}
                alt={`Product ${index + 1}`}
                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              />
            ) : (
              <ImageIcon sx={{ fontSize: 48, color: 'text.disabled' }} />
            )}
          </Box>
          <TextField
            fullWidth
            label={t('products.form.imageUrl')}
            value={img.imageUrl}
            onChange={(e) => updateImage(index, 'imageUrl', e.target.value)}
            size="small"
            sx={{ mb: 1 }}
          />
          <FormControlLabel
            control={
              <Switch
                checked={img.isPrimary}
                onChange={(e) => updateImage(index, 'isPrimary', e.target.checked)}
                size="small"
              />
            }
            label={t('products.form.setPrimary')}
          />
        </Box>
      </Grid>
    );
  };

  // Form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    // Validation
    if (!formData.title.trim()) {
      setError(t('products.form.titleRequired'));
      return;
    }
    if (!formData.storeId) {
      setError(t('products.form.storeRequired'));
      return;
    }
    if (!formData.ownerOrgId.trim()) {
      setError(t('products.form.organizationRequired'));
      return;
    }
    if (!formData.sku.trim()) {
      setError(t('products.form.skuRequired'));
      return;
    }

    setSaving(true);
    try {
      const productData: CreateProductData = {
        sku: formData.sku,
        title: formData.title,
        description: formData.description || undefined,
        storeId: Number(formData.storeId),
        ownerOrgId: formData.ownerOrgId,
        mainPrice: formData.mainPrice ? Number(formData.mainPrice) : undefined,
        strikethroughPrice: formData.strikethroughPrice ? Number(formData.strikethroughPrice) : undefined,
        costPrice: formData.costPrice ? Number(formData.costPrice) : undefined,
        stockLeft: Number(formData.stockLeft) || 0,
        minimumOrderQuantity: Number(formData.minimumOrderQuantity) || 1,
        logisticsWeight: formData.weight ? Number(formData.weight) : undefined,
        shelfCode: formData.shelfCode || undefined,
        isActive: formData.isActive,
        isFeatured: formData.isFeatured,
        isMiniAppRecommendation: formData.isMiniAppRecommendation,
        productType: formData.productType,
        visibility: formData.visibility,
        etwStoreType: formData.etwStoreType || undefined,
        etwMiniAppType: formData.etwMiniAppType || undefined,
        categoryIds: formData.categoryIds,
        subcategoryIds: formData.subcategoryIds,
        collectionIds: formData.collectionIds,
        subcollectionIds: formData.subcollectionIds,
        attributes: attributes.filter((a) => a.attributeName && a.attributeValue).map((a) => ({
          attributeName: a.attributeName,
          attributeValue: a.attributeValue,
          displayOrder: a.displayOrder,
          isVariantDefining: a.isVariantDefining,
        })),
        images: images.filter((i) => i.imageUrl).map((i) => ({
          imageUrl: i.imageUrl,
          displayOrder: i.displayOrder,
          isPrimary: i.isPrimary,
        })),
      };

      if (isEditing && id) {
        await productApi.updateProduct(id, productData);
        setSuccess(t('products.form.updateSuccess'));
      } else {
        const created = await productApi.createProduct(productData);
        setSuccess(t('products.form.createSuccess'));
        // Navigate to the created product
        setTimeout(() => navigate(`/products/${created.id}`), 1500);
      }
    } catch (err) {
      console.error('Failed to save product:', err);
      setError(isEditing ? t('products.form.updateError') : t('products.form.createError'));
    } finally {
      setSaving(false);
    }
  };

  const breadcrumbs = [
    { label: t('nav.products'), path: '/products' },
    { label: isEditing ? t('products.editProduct') : t('products.addProduct') },
  ];

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box component="form" onSubmit={handleSubmit}>
      {/* Page Header */}
      <PageHeader
        title={isEditing ? t('products.editProduct') : t('products.addProduct')}
        breadcrumbs={breadcrumbs}
        actions={
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button
              variant="outlined"
              startIcon={<BackIcon />}
              onClick={() => navigate('/products')}
            >
              {t('common.back')}
            </Button>
            <Button
              type="submit"
              variant="contained"
              startIcon={saving ? <CircularProgress size={16} color="inherit" /> : <SaveIcon />}
              disabled={saving}
            >
              {saving ? t('common.saving') : t('common.save')}
            </Button>
          </Box>
        }
      />

      {/* Alerts */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}
      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
          {success}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Left Column - Main Information */}
        <Grid item xs={12} lg={8}>
          {/* Basic Information */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('products.form.basicInfo')}
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    required
                    label={t('products.form.sku')}
                    value={formData.sku}
                    onChange={(e) => handleChange('sku', e.target.value)}
                    size="small"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label={t('products.form.shelfCode')}
                    value={formData.shelfCode}
                    onChange={(e) => handleChange('shelfCode', e.target.value)}
                    size="small"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    required
                    label={t('products.productName')}
                    value={formData.title}
                    onChange={(e) => handleChange('title', e.target.value)}
                    size="small"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    multiline
                    rows={4}
                    label={t('products.productDescription')}
                    value={formData.description}
                    onChange={(e) => handleChange('description', e.target.value)}
                    size="small"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* Pricing */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('products.form.pricing')}
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={4}>
                  <TextField
                    fullWidth
                    type="number"
                    label={t('products.currentPrice')}
                    value={formData.mainPrice}
                    onChange={(e) => handleChange('mainPrice', e.target.value)}
                    InputProps={{
                      startAdornment: <InputAdornment position="start">$</InputAdornment>,
                    }}
                    size="small"
                  />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <TextField
                    fullWidth
                    type="number"
                    label={t('products.originalPrice')}
                    value={formData.strikethroughPrice}
                    onChange={(e) => handleChange('strikethroughPrice', e.target.value)}
                    InputProps={{
                      startAdornment: <InputAdornment position="start">$</InputAdornment>,
                    }}
                    size="small"
                    helperText={t('products.form.strikethroughHelp')}
                  />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <TextField
                    fullWidth
                    type="number"
                    label={t('products.form.costPrice')}
                    value={formData.costPrice}
                    onChange={(e) => handleChange('costPrice', e.target.value)}
                    InputProps={{
                      startAdornment: <InputAdornment position="start">$</InputAdornment>,
                    }}
                    size="small"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* Inventory */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('products.form.inventory')}
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={4}>
                  <TextField
                    fullWidth
                    type="number"
                    label={t('products.stock')}
                    value={formData.stockLeft}
                    onChange={(e) => handleChange('stockLeft', e.target.value)}
                    size="small"
                  />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <TextField
                    fullWidth
                    type="number"
                    label={t('products.minOrderQty')}
                    value={formData.minimumOrderQuantity}
                    onChange={(e) => handleChange('minimumOrderQuantity', e.target.value)}
                    size="small"
                    helperText={t('products.form.minOrderHelp')}
                  />
                </Grid>
                <Grid item xs={12} sm={4}>
                  <TextField
                    fullWidth
                    type="number"
                    label={t('products.form.weight')}
                    value={formData.weight}
                    onChange={(e) => handleChange('weight', e.target.value)}
                    InputProps={{
                      endAdornment: <InputAdornment position="end">g</InputAdornment>,
                    }}
                    size="small"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* Attributes */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6">
                  {t('products.form.attributes')}
                </Typography>
                <Button
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={addAttribute}
                >
                  {t('products.form.addAttribute')}
                </Button>
              </Box>
              {attributes.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  {t('products.form.noAttributes')}
                </Typography>
              ) : (
                attributes.map((attr, index) => (
                  <Box
                    key={index}
                    sx={{
                      display: 'flex',
                      gap: 2,
                      alignItems: 'center',
                      mb: 2,
                      p: 2,
                      bgcolor: 'action.hover',
                      borderRadius: 1,
                    }}
                  >
                    <DragIcon sx={{ color: 'text.secondary', cursor: 'grab' }} />
                    <TextField
                      label={t('products.form.attributeName')}
                      value={attr.attributeName}
                      onChange={(e) => updateAttribute(index, 'attributeName', e.target.value)}
                      size="small"
                      sx={{ flex: 1 }}
                    />
                    <TextField
                      label={t('products.form.attributeValue')}
                      value={attr.attributeValue}
                      onChange={(e) => updateAttribute(index, 'attributeValue', e.target.value)}
                      size="small"
                      sx={{ flex: 1 }}
                    />
                    <FormControlLabel
                      control={
                        <Switch
                          checked={attr.isVariantDefining}
                          onChange={(e) => updateAttribute(index, 'isVariantDefining', e.target.checked)}
                          size="small"
                        />
                      }
                      label={t('products.form.variantDefining')}
                    />
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => removeAttribute(index)}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </Box>
                ))
              )}
            </CardContent>
          </Card>

          {/* Images */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6">
                  {t('products.images')}
                </Typography>
                <Button
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={addImage}
                >
                  {t('products.addImage')}
                </Button>
              </Box>
              {images.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  {t('products.form.noImages')}
                </Typography>
              ) : (
                <DndContext
                  sensors={imageSensors}
                  collisionDetection={closestCenter}
                  onDragEnd={handleImageDragEnd}
                >
                  <SortableContext
                    items={images.map(img => img.id)}
                    strategy={rectSortingStrategy}
                  >
                    <Grid container spacing={2}>
                      {images.map((img, index) => (
                        <SortableImageCard key={img.id} img={img} index={index} />
                      ))}
                    </Grid>
                  </SortableContext>
                </DndContext>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Right Column - Settings */}
        <Grid item xs={12} lg={4}>
          {/* Organization & Store */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('products.form.organization')}
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    required
                    label={t('products.form.organizationId')}
                    value={formData.ownerOrgId}
                    onChange={(e) => handleChange('ownerOrgId', e.target.value)}
                    size="small"
                    helperText={t('products.form.organizationIdHelp')}
                  />
                </Grid>
                <Grid item xs={12}>
                  <FormControl fullWidth size="small" required>
                    <InputLabel>{t('products.store')}</InputLabel>
                    <Select
                      value={formData.storeId}
                      label={t('products.store')}
                      onChange={(e) => handleChange('storeId', e.target.value)}
                    >
                      {stores.map((store) => (
                        <MenuItem key={store.id} value={store.id}>
                          {store.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* Category */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('products.form.categorization')}
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <FormControl fullWidth size="small">
                    <InputLabel>{t('products.category')}</InputLabel>
                    <Select
                      value={formData.categoryIds[0] || ''}
                      label={t('products.category')}
                      onChange={(e) => handleCategoryChange(Number(e.target.value))}
                    >
                      <MenuItem value="">
                        <em>{t('common.none')}</em>
                      </MenuItem>
                      {categories.map((cat) => (
                        <MenuItem key={cat.id} value={cat.id}>
                          {cat.name}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
                {subcategories.length > 0 && (
                  <Grid item xs={12}>
                    <FormControl fullWidth size="small">
                      <InputLabel>{t('products.subcategory')}</InputLabel>
                      <Select
                        value={formData.subcategoryIds[0] || ''}
                        label={t('products.subcategory')}
                        onChange={(e) => handleSubcategoryChange(Number(e.target.value))}
                      >
                        <MenuItem value="">
                          <em>{t('common.none')}</em>
                        </MenuItem>
                        {subcategories.map((subcat) => (
                          <MenuItem key={subcat.id} value={subcat.id}>
                            {subcat.name}
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                )}
                {collections.length > 0 && (
                  <Grid item xs={12}>
                    <FormControl fullWidth size="small">
                      <InputLabel>{t('products.collection')}</InputLabel>
                      <Select
                        value={formData.collectionIds[0] || ''}
                        label={t('products.collection')}
                        onChange={(e) => handleCollectionChange(Number(e.target.value))}
                      >
                        <MenuItem value="">
                          <em>{t('common.none')}</em>
                        </MenuItem>
                        {collections.map((col) => (
                          <MenuItem key={col.id} value={col.id}>
                            {col.name}
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                )}
                {subcollections.length > 0 && (
                  <Grid item xs={12}>
                    <FormControl fullWidth size="small">
                      <InputLabel>{t('products.subcollection')}</InputLabel>
                      <Select
                        value={formData.subcollectionIds[0] || ''}
                        label={t('products.subcollection')}
                        onChange={(e) => handleChange('subcollectionIds', e.target.value ? [Number(e.target.value)] : [])}
                      >
                        <MenuItem value="">
                          <em>{t('common.none')}</em>
                        </MenuItem>
                        {subcollections.map((subcol) => (
                          <MenuItem key={subcol.id} value={subcol.id}>
                            {subcol.name}
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                )}
              </Grid>
            </CardContent>
          </Card>

          {/* Product Type & Visibility */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('products.form.productSettings')}
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <FormControl fullWidth size="small">
                    <InputLabel>{t('products.form.productType')}</InputLabel>
                    <Select
                      value={formData.productType}
                      label={t('products.form.productType')}
                      onChange={(e) => handleChange('productType', e.target.value)}
                    >
                      <MenuItem value="standard">{t('products.form.typeStandard')}</MenuItem>
                      <MenuItem value="parent">{t('products.form.typeParent')}</MenuItem>
                      <MenuItem value="child">{t('products.form.typeChild')}</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={12}>
                  <FormControl fullWidth size="small">
                    <InputLabel>{t('products.form.visibility')}</InputLabel>
                    <Select
                      value={formData.visibility}
                      label={t('products.form.visibility')}
                      onChange={(e) => handleChange('visibility', e.target.value)}
                    >
                      <MenuItem value="visible">{t('products.form.visibilityVisible')}</MenuItem>
                      <MenuItem value="not_visible">{t('products.form.visibilityHidden')}</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* ETW Types */}
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('products.form.etwSettings')}
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <FormControl fullWidth size="small">
                    <InputLabel>{t('products.form.etwStoreType')}</InputLabel>
                    <Select
                      value={formData.etwStoreType}
                      label={t('products.form.etwStoreType')}
                      onChange={(e) => handleChange('etwStoreType', e.target.value)}
                    >
                      <MenuItem value="">
                        <em>{t('common.none')}</em>
                      </MenuItem>
                      <MenuItem value="mega">MEGA</MenuItem>
                      <MenuItem value="market">MARKET</MenuItem>
                      <MenuItem value="toGo">toGO</MenuItem>
                      <MenuItem value="xpress">XPRESS</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={12}>
                  <FormControl fullWidth size="small">
                    <InputLabel>{t('products.form.etwMiniAppType')}</InputLabel>
                    <Select
                      value={formData.etwMiniAppType}
                      label={t('products.form.etwMiniAppType')}
                      onChange={(e) => handleChange('etwMiniAppType', e.target.value)}
                    >
                      <MenuItem value="">
                        <em>{t('common.none')}</em>
                      </MenuItem>
                      <MenuItem value="shopping">Shopping</MenuItem>
                      <MenuItem value="food">Food</MenuItem>
                      <MenuItem value="service">Service</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* Status Toggles */}
          <Card elevation={0}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('common.status')}
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.isActive}
                      onChange={(e) => handleChange('isActive', e.target.checked)}
                    />
                  }
                  label={t('products.active')}
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.isFeatured}
                      onChange={(e) => handleChange('isFeatured', e.target.checked)}
                    />
                  }
                  label={t('products.featured')}
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.isMiniAppRecommendation}
                      onChange={(e) => handleChange('isMiniAppRecommendation', e.target.checked)}
                    />
                  }
                  label={t('products.form.miniAppRecommendation')}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default ProductFormPage;
