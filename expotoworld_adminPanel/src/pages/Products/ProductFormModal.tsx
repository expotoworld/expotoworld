import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Grid,
  Typography,
  IconButton,
  CircularProgress,
  Alert,
  InputAdornment,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Save as SaveIcon,
  Add as AddIcon,
  Delete as DeleteIcon,
  Image as ImageIcon,
  Close as CloseIcon,
  CloudUpload as CloudUploadIcon,
} from '@mui/icons-material';
import { CustomDropdown } from '@components/common';
import { VariationOptionsEditor, type VariationOption } from '@components/products';
import {
  productApi,
  categoryApi,
  storeApi,
  specificationApi,
  type Category,
  type Subcategory,
  type Store,
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
  taxRate: string;
  stockLeft: string;
  minimumOrderQuantity: string;
  shelfCode: string;
  netContent: string;
  contentUnit: string;
  referencePrice: string;
  referenceUnit: string;
  logisticsLength: string;
  logisticsWidth: string;
  logisticsHeight: string;
  logisticsWeight: string;
  logisticsVolume: string;
  categoryId: string;
  subcategoryId: string;
  productType: 'standalone' | 'parent' | 'child';
  visibility: 'visible' | 'hidden' | 'featured';
  variationOptions: VariationOption[];
  etwStore: string;
  miniAppType: string;
  isActive: boolean;
  isFeatured: boolean;
  specifications: Array<{ name: string; value: string }>;
  images: Array<{ 
    url: string; 
    isPrimary: boolean; 
    file?: File; 
    uploading?: boolean; 
    uploadProgress?: number;
    previewUrl?: string;
  }>;
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
  taxRate: '22',
  stockLeft: '0',
  minimumOrderQuantity: '1',
  shelfCode: '',
  netContent: '',
  contentUnit: '',
  referencePrice: '',
  referenceUnit: '',
  logisticsLength: '',
  logisticsWidth: '',
  logisticsHeight: '',
  logisticsWeight: '',
  logisticsVolume: '',
  categoryId: '',
  subcategoryId: '',
  productType: 'standalone',
  visibility: 'visible',
  variationOptions: [],
  etwStore: '',
  miniAppType: '',
  isActive: true,
  isFeatured: false,
  specifications: [],
  images: [],
};

interface ProductFormModalProps {
  open: boolean;
  productId?: string;
  parentId?: string; // For creating child products
  onClose: () => void;
  onSuccess: () => void;
}

const ProductFormModal: React.FC<ProductFormModalProps> = ({
  open,
  productId,
  parentId,
  onClose,
  onSuccess,
}) => {
  const { t } = useTranslation();
  const isEditMode = !!productId;
  const isChildMode = !!parentId;

  // Form state
  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Reference data - using category tree for subcategories
  const [categoryTree, setCategoryTree] = useState<Array<Category & { subcategories: Subcategory[] }>>([]);
  const [stores, setStores] = useState<Store[]>([]);

  // Fetch reference data
  const fetchReferenceData = useCallback(async () => {
    try {
      const [categoriesRes, storesRes] = await Promise.all([
        categoryApi.getCategoryTree(),
        storeApi.getStores({ page_size: 100 }),
      ]);
      setCategoryTree(categoriesRes);
      setStores(storesRes.items);
    } catch (err) {
      console.error('Failed to fetch reference data:', err);
    }
  }, []);

  // Fetch product data for edit mode
  const fetchProduct = useCallback(async () => {
    if (!productId) return;
    
    setLoading(true);
    setError(null);
    try {
      const product = await productApi.getProduct(productId);
      // Convert variant_options_index from API format (Record<string, Array>) to component format (VariationOption[])
      const variationOpts: VariationOption[] = [];
      if (product.variantOptionsIndex) {
        for (const [optionName, vals] of Object.entries(product.variantOptionsIndex)) {
          if (Array.isArray(vals)) {
            variationOpts.push({
              name: optionName,
              values: vals.map((v: { value?: string; display_order?: number }) => ({
                value: String(v.value ?? ''),
                displayOrder: typeof v.display_order === 'number' ? v.display_order : 0,
              })),
            });
          }
        }
      }
      setFormData({
        sku: product.sku || '',
        title: product.name || '',
        description: product.description || '',
        storeId: product.storeId || '',
        ownerOrgId: product.organizationId || '',
        mainPrice: product.currentPrice?.toString() || '',
        strikethroughPrice: product.originalPrice?.toString() || '',
        costPrice: product.costPrice?.toString() || '',
        taxRate: product.taxRate?.toString() || '22',
        stockLeft: product.stockLeft?.toString() || '0',
        minimumOrderQuantity: product.minimumOrderQuantity?.toString() || '1',
        shelfCode: product.shelfCode || '',
        netContent: product.netContent?.toString() || '',
        contentUnit: product.contentUnit || '',
        referencePrice: product.referencePrice?.toString() || '',
        referenceUnit: product.referenceUnit || '',
        logisticsLength: product.logisticsLength?.toString() || '',
        logisticsWidth: product.logisticsWidth?.toString() || '',
        logisticsHeight: product.logisticsHeight?.toString() || '',
        logisticsWeight: product.logisticsWeight?.toString() || '',
        logisticsVolume: product.logisticsVolume?.toString() || '',
        categoryId: product.categoryId || '',
        subcategoryId: product.subcategoryId || '',
        productType: product.parentId ? 'child' : (product.productType === 'parent' ? 'parent' : 'standalone'),
        visibility: product.isFeatured ? 'featured' : (product.isActive ? 'visible' : 'hidden'),
        variationOptions: variationOpts,
        etwStore: product.etwStoreType || '',
        miniAppType: product.etwMiniAppType || '',
        isActive: product.isActive ?? true,
        isFeatured: product.isFeatured ?? false,
        specifications: product.specifications?.map(spec => ({
          name: spec.specName,
          value: spec.specValue,
        })) || [],
        images: product.imageUrls?.map((url, idx) => ({
          url,
          isPrimary: idx === 0,
        })) || [],
      });
    } catch (err) {
      console.error('Failed to fetch product:', err);
      setError(t('products.fetchError') || 'Failed to load product');
    } finally {
      setLoading(false);
    }
  }, [productId, t]);

  useEffect(() => {
    if (open) {
      fetchReferenceData();
    }
  }, [open, fetchReferenceData]);

  useEffect(() => {
    if (open && isEditMode) {
      fetchProduct();
    } else if (open && !isEditMode) {
      // Reset form for new product
      setFormData({
        ...initialFormData,
        productType: isChildMode ? 'child' : 'standalone',
      });
    }
  }, [open, isEditMode, isChildMode, fetchProduct]);

  // Get subcategories for selected category
  const getSubcategories = (categoryId: string): Subcategory[] => {
    const category = categoryTree.find(c => c.id === categoryId);
    return category?.subcategories || [];
  };

  // Handle category change
  const handleCategoryChange = (categoryId: string) => {
    setFormData(prev => ({ ...prev, categoryId, subcategoryId: '' }));
  };

  // Handle store change - auto-populate ETW settings from store
  const handleStoreChange = (storeId: string) => {
    const selectedStore = stores.find(s => s.id === storeId);
    setFormData(prev => ({
      ...prev,
      storeId,
      etwStore: selectedStore?.etwStoreType || '',
      miniAppType: selectedStore?.etwMiniAppType || '',
    }));
  };

  // Get selected store for ETW display
  const selectedStore = stores.find(s => s.id === formData.storeId);

  // Auto-calculate reference price based on net content, content unit, and main price
  // Reference price = mainPrice / netContent * referenceUnitMultiplier
  // E.g., if product is 500g at €10, reference price per KG = (10/500) * 1000 = €20.00/KG
  const calculateReferencePrice = (mainPrice: string, netContent: string, contentUnit: string, referenceUnit: string): string => {
    const price = parseFloat(mainPrice);
    const content = parseFloat(netContent);
    
    if (!price || !content || content <= 0 || !referenceUnit) return '';
    
    // Convert content to reference unit basis
    let contentInRefUnit = content;
    const contentUnitLower = contentUnit.toLowerCase();
    
    // Handle g → KG conversion
    if ((contentUnitLower === 'g') && referenceUnit === 'KG') {
      contentInRefUnit = content / 1000;
    }
    // Handle mL → L conversion
    else if ((contentUnitLower === 'ml') && referenceUnit === 'L') {
      contentInRefUnit = content / 1000;
    }
    // Handle cm → M conversion
    else if ((contentUnitLower === 'cm') && referenceUnit === 'M') {
      contentInRefUnit = content / 100;
    }
    
    // Calculate reference price (price per 1 reference unit)
    const refPrice = price / contentInRefUnit;
    return refPrice.toFixed(4);
  };

  // Auto-select reference unit based on content unit
  // g/KG → KG, mL/L → L, cm/M → M, PC/PCS/Unit → same
  const getAutoReferenceUnit = (contentUnit: string): string => {
    const unitLower = contentUnit.toLowerCase();
    if (unitLower === 'g' || unitLower === 'kg') {
      return 'KG';
    } else if (unitLower === 'ml' || unitLower === 'l') {
      return 'L';
    } else if (unitLower === 'cm' || unitLower === 'm') {
      return 'M';
    } else if (unitLower === 'pc') {
      return 'PC';
    } else if (unitLower === 'pcs') {
      return 'PCS';
    } else if (unitLower === 'unit') {
      return 'Unit';
    }
    return '';
  };

  // Handle form field changes with auto-calculation
  const handleChange = (field: keyof FormData, value: unknown) => {
    setFormData(prev => {
      const updated = { ...prev, [field]: value };
      
      // Auto-select reference unit when content unit changes
      if (field === 'contentUnit') {
        const autoRefUnit = getAutoReferenceUnit(value as string);
        if (autoRefUnit) {
          updated.referenceUnit = autoRefUnit;
        }
        // Recalculate reference price if we have the other values
        if (updated.mainPrice && updated.netContent && updated.referenceUnit) {
          updated.referencePrice = calculateReferencePrice(
            updated.mainPrice, 
            updated.netContent, 
            value as string,
            updated.referenceUnit
          );
        }
      }
      
      // Recalculate reference price when mainPrice, netContent, or referenceUnit changes
      if (field === 'mainPrice' || field === 'netContent' || field === 'referenceUnit') {
        if (updated.mainPrice && updated.netContent && updated.referenceUnit && updated.contentUnit) {
          updated.referencePrice = calculateReferencePrice(
            updated.mainPrice, 
            updated.netContent, 
            updated.contentUnit,
            updated.referenceUnit
          );
        }
      }
      
      // Auto-calculate package volume when length, width, or height changes
      if (field === 'logisticsLength' || field === 'logisticsWidth' || field === 'logisticsHeight') {
        const length = parseFloat(field === 'logisticsLength' ? String(value) : String(updated.logisticsLength)) || 0;
        const width = parseFloat(field === 'logisticsWidth' ? String(value) : String(updated.logisticsWidth)) || 0;
        const height = parseFloat(field === 'logisticsHeight' ? String(value) : String(updated.logisticsHeight)) || 0;
        
        if (length > 0 && width > 0 && height > 0) {
          updated.logisticsVolume = String(length * width * height);
        }
      }
      
      return updated;
    });
  };

  // Handle specification changes
  const addSpecification = () => {
    setFormData(prev => ({
      ...prev,
      specifications: [...prev.specifications, { name: '', value: '' }],
    }));
  };

  const updateSpecification = (index: number, field: 'name' | 'value', value: string) => {
    setFormData(prev => ({
      ...prev,
      specifications: prev.specifications.map((spec, i) =>
        i === index ? { ...spec, [field]: value } : spec
      ),
    }));
  };

  const removeSpecification = (index: number) => {
    setFormData(prev => ({
      ...prev,
      specifications: prev.specifications.filter((_, i) => i !== index),
    }));
  };

  // Handle image changes
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = useState(false);

  const handleFileSelect = async (files: FileList | null) => {
    if (!files || files.length === 0) return;
    
    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    const maxSize = 10 * 1024 * 1024; // 10MB
    
    const newImages = Array.from(files).filter(file => {
      if (!validTypes.includes(file.type)) {
        console.warn(`Invalid file type: ${file.name}`);
        return false;
      }
      if (file.size > maxSize) {
        console.warn(`File too large: ${file.name}`);
        return false;
      }
      return true;
    }).map((file, idx) => ({
      url: '',
      isPrimary: formData.images.length === 0 && idx === 0,
      file,
      uploading: false,
      uploadProgress: 0,
      previewUrl: URL.createObjectURL(file),
    }));

    if (newImages.length > 0) {
      setFormData(prev => ({
        ...prev,
        images: [...prev.images, ...newImages],
      }));
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    handleFileSelect(e.dataTransfer.files);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
  };

  const removeImage = (index: number) => {
    setFormData(prev => {
      const removedImage = prev.images[index];
      // Revoke object URL to free memory
      if (removedImage?.previewUrl) {
        URL.revokeObjectURL(removedImage.previewUrl);
      }
      const newImages = prev.images.filter((_, i) => i !== index);
      // If removed image was primary, make first remaining image primary
      if (removedImage?.isPrimary && newImages.length > 0) {
        newImages[0].isPrimary = true;
      }
      return { ...prev, images: newImages };
    });
  };

  // Clean up preview URLs when component unmounts
  useEffect(() => {
    return () => {
      formData.images.forEach(img => {
        if (img.previewUrl) {
          URL.revokeObjectURL(img.previewUrl);
        }
      });
    };
  }, []);

  const setPrimaryImage = (index: number) => {
    setFormData(prev => ({
      ...prev,
      images: prev.images.map((img, i) => ({
        ...img,
        isPrimary: i === index,
      })),
    }));
  };

  // Handle form submission
  const handleSubmit = async () => {
    setSaving(true);
    setError(null);

    try {
      // Convert variation options from component format (Array) to API format (Record<string, Array>)
      const apiVariantOptionsIndex: Record<string, Array<{ value: string; display_order: number }>> = {};
      if (formData.productType === 'parent' && formData.variationOptions.length > 0) {
        for (const opt of formData.variationOptions) {
          apiVariantOptionsIndex[opt.name] = opt.values.map(v => ({
            value: v.value,
            display_order: v.displayOrder,
          }));
        }
      }

      // Temporary product ID for uploading images before creation
      // For existing products, use productId; for new products, we'll use a temp ID
      const tempProductId = productId || `temp-${Date.now()}`;
      
      // Upload any pending files to S3
      const uploadedImages: Array<{ url: string; isPrimary: boolean }> = [];
      for (let i = 0; i < formData.images.length; i++) {
        const img = formData.images[i];
        if (img.file && !img.url) {
          // Update upload status
          setFormData(prev => ({
            ...prev,
            images: prev.images.map((im, idx) => 
              idx === i ? { ...im, uploading: true, uploadProgress: 0 } : im
            ),
          }));

          try {
            const publicUrl = await productApi.uploadAndCreateImage(
              tempProductId,
              img.file,
              i,
              img.isPrimary,
              (progress) => {
                setFormData(prev => ({
                  ...prev,
                  images: prev.images.map((im, idx) => 
                    idx === i ? { ...im, uploadProgress: progress } : im
                  ),
                }));
              }
            );
            
            uploadedImages.push({ url: publicUrl, isPrimary: img.isPrimary });
            
            // Update the image with the uploaded URL
            setFormData(prev => ({
              ...prev,
              images: prev.images.map((im, idx) => 
                idx === i ? { ...im, url: publicUrl, uploading: false, uploadProgress: 100 } : im
              ),
            }));
          } catch (uploadErr) {
            console.error('Failed to upload image:', uploadErr);
            setFormData(prev => ({
              ...prev,
              images: prev.images.map((im, idx) => 
                idx === i ? { ...im, uploading: false } : im
              ),
            }));
            throw new Error(`Failed to upload image ${i + 1}`);
          }
        } else if (img.url) {
          // Already has a URL (existing image or manually entered URL)
          uploadedImages.push({ url: img.url, isPrimary: img.isPrimary });
        }
      }

      // Prepare product data using Partial<Product> format for the API
      const productData = {
        sku: formData.sku || undefined,
        name: formData.title,
        description: formData.description || undefined,
        storeId: formData.storeId || undefined,
        organizationId: formData.ownerOrgId || undefined,
        currentPrice: parseFloat(formData.mainPrice) || 0,
        originalPrice: parseFloat(formData.strikethroughPrice) || parseFloat(formData.mainPrice) || 0,
        costPrice: parseFloat(formData.costPrice) || undefined,
        taxRate: parseFloat(formData.taxRate) || undefined,
        stockLeft: parseInt(formData.stockLeft) || 0,
        minimumOrderQuantity: parseInt(formData.minimumOrderQuantity) || 1,
        shelfCode: formData.shelfCode || undefined,
        netContent: parseFloat(formData.netContent) || undefined,
        contentUnit: formData.contentUnit || undefined,
        referencePrice: parseFloat(formData.referencePrice) || undefined,
        referenceUnit: formData.referenceUnit || undefined,
        logisticsLength: parseFloat(formData.logisticsLength) || undefined,
        logisticsWidth: parseFloat(formData.logisticsWidth) || undefined,
        logisticsHeight: parseFloat(formData.logisticsHeight) || undefined,
        logisticsWeight: parseFloat(formData.logisticsWeight) || undefined,
        logisticsVolume: parseFloat(formData.logisticsVolume) || undefined,
        categoryId: formData.categoryId || undefined,
        subcategoryId: formData.subcategoryId || undefined,
        productType: formData.productType,
        variantOptionsIndex: formData.productType === 'parent' ? apiVariantOptionsIndex : undefined,
        etwStoreType: formData.etwStore || undefined,
        etwMiniAppType: formData.miniAppType || undefined,
        isActive: formData.visibility !== 'hidden',
        isFeatured: formData.visibility === 'featured',
        imageUrls: uploadedImages
          .sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0))
          .map(img => img.url),
      };

      let savedProductId: string | undefined;

      if (isEditMode && productId) {
        await productApi.updateProduct(productId, productData);
        savedProductId = productId;
      } else if (isChildMode && parentId) {
        // For child product creation, use the createChildProduct API with proper format
        const childData = {
          sku: formData.sku || undefined,
          title: formData.title,
          description: formData.description || undefined,
          storeId: formData.storeId ? Number(formData.storeId) : undefined,
          mainPrice: parseFloat(formData.mainPrice) || 0,
          strikethroughPrice: parseFloat(formData.strikethroughPrice) || parseFloat(formData.mainPrice) || 0,
          costPrice: parseFloat(formData.costPrice) || undefined,
          stockLeft: parseInt(formData.stockLeft) || 0,
          minimumOrderQuantity: parseInt(formData.minimumOrderQuantity) || 1,
          shelfCode: formData.shelfCode || undefined,
          isActive: formData.visibility !== 'hidden',
          isFeatured: formData.visibility === 'featured',
          productType: 'child' as const,
          categoryIds: formData.categoryId ? [Number(formData.categoryId)] : [],
          subcategoryIds: formData.subcategoryId ? [Number(formData.subcategoryId)] : [],
          images: formData.images
            .filter(img => img.url)
            .map((img, idx) => ({
              imageUrl: img.url,
              displayOrder: idx,
              isPrimary: img.isPrimary,
            })),
        };
        const createdChild = await productApi.createChildProduct(parentId, childData);
        savedProductId = createdChild.id;
      } else {
        const createdProduct = await productApi.createProduct(productData);
        savedProductId = createdProduct.id;
      }

      // Save specifications separately for all product types
      if (savedProductId && formData.specifications.length > 0) {
        const validSpecs = formData.specifications.filter(spec => spec.name && spec.value);
        if (validSpecs.length > 0) {
          await specificationApi.replaceAllSpecifications(
            savedProductId,
            validSpecs.map((spec, idx) => ({
              specName: spec.name,
              specValue: spec.value,
              displayOrder: idx,
            }))
          );
        }
      }

      onSuccess();
      onClose();
    } catch (err) {
      console.error('Failed to save product:', err);
      setError(
        isEditMode
          ? (t('products.updateError') || 'Failed to update product')
          : (t('products.createError') || 'Failed to create product')
      );
    } finally {
      setSaving(false);
    }
  };

  const getTitle = () => {
    if (isEditMode) return t('products.editProduct');
    if (isChildMode) return t('products.detail.addVariant');
    return t('products.addProduct');
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="lg"
      fullWidth
      PaperProps={{
        sx: { maxHeight: '90vh' }
      }}
    >
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography variant="h6">{getTitle()}</Typography>
        <IconButton onClick={onClose} size="small">
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent dividers>
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress />
          </Box>
        ) : (
          <Box sx={{ py: 1 }}>
            {error && (
              <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
                {error}
              </Alert>
            )}

            <Grid container spacing={3}>
              {/* Basic Information */}
              <Grid item xs={12}>
                <Typography variant="subtitle1" fontWeight={600} gutterBottom>
                  {t('products.form.basicInfo')}
                </Typography>
              </Grid>

              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.sku')}
                  value={formData.sku}
                  onChange={(e) => handleChange('sku', e.target.value)}
                />
              </Grid>
              <Grid item xs={12} md={8}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.productName')}
                  value={formData.title}
                  onChange={(e) => handleChange('title', e.target.value)}
                  required
                  placeholder={t('products.form.namePlaceholder')}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.productDescription')}
                  value={formData.description}
                  onChange={(e) => handleChange('description', e.target.value)}
                  multiline
                  rows={3}
                  placeholder={t('products.form.descriptionPlaceholder')}
                />
              </Grid>

              {/* Category and Store */}
              <Grid item xs={12} md={6}>
                <CustomDropdown
                  label={t('products.category')}
                  value={formData.categoryId}
                  options={[
                    { value: '', label: t('products.form.selectCategory') },
                    ...categoryTree.map((cat) => ({ value: cat.id, label: cat.name })),
                  ]}
                  onChange={(value) => handleCategoryChange(value)}
                  required
                  fullWidth
                  size="small"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <CustomDropdown
                  label={t('products.subcategory')}
                  value={formData.subcategoryId}
                  options={[
                    { value: '', label: t('products.form.selectSubcategory') },
                    ...getSubcategories(formData.categoryId).map((sub) => ({ value: sub.id, label: sub.name })),
                  ]}
                  onChange={(value) => handleChange('subcategoryId', value)}
                  disabled={!formData.categoryId}
                  fullWidth
                  size="small"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <CustomDropdown
                  label={t('products.store')}
                  value={formData.storeId}
                  options={[
                    { value: '', label: t('products.form.selectStore') },
                    ...stores.map((store) => ({ value: store.id, label: store.name })),
                  ]}
                  onChange={handleStoreChange}
                  required
                  fullWidth
                  size="small"
                />
              </Grid>

              {/* ETW Settings - Auto-inherited from store (read-only display) */}
              {selectedStore && (selectedStore.etwStoreType || selectedStore.etwMiniAppType) && (
                <Grid item xs={12}>
                  <Box sx={{ display: 'flex', gap: 2, mt: 1, flexWrap: 'wrap' }}>
                    {selectedStore.etwStoreType && (
                      <Chip
                        size="small"
                        label={`${t('products.form.etwStore')}: ${selectedStore.etwStoreType}`}
                        color="primary"
                        variant="outlined"
                      />
                    )}
                    {selectedStore.etwMiniAppType && (
                      <Chip
                        size="small"
                        label={`${t('products.form.miniAppType')}: ${selectedStore.etwMiniAppType}`}
                        color="secondary"
                        variant="outlined"
                      />
                    )}
                  </Box>
                </Grid>
              )}

              {/* Pricing */}
              <Grid item xs={12}>
                <Typography variant="subtitle1" fontWeight={600} gutterBottom sx={{ mt: 2 }}>
                  {t('products.form.pricing')}
                </Typography>
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.currentPrice')}
                  value={formData.mainPrice}
                  onChange={(e) => handleChange('mainPrice', e.target.value)}
                  type="number"
                  required
                  InputProps={{
                    startAdornment: <InputAdornment position="start">€</InputAdornment>,
                  }}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.originalPrice')}
                  value={formData.strikethroughPrice}
                  onChange={(e) => handleChange('strikethroughPrice', e.target.value)}
                  type="number"
                  InputProps={{
                    startAdornment: <InputAdornment position="start">€</InputAdornment>,
                  }}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField
                  fullWidth
                  size="small"
                  label="Cost Price"
                  value={formData.costPrice}
                  onChange={(e) => handleChange('costPrice', e.target.value)}
                  type="number"
                  placeholder={t('products.form.costPricePlaceholder')}
                  InputProps={{
                    startAdornment: <InputAdornment position="start">€</InputAdornment>,
                  }}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.taxRate')}
                  value={formData.taxRate}
                  onChange={(e) => handleChange('taxRate', e.target.value)}
                  type="number"
                  placeholder={t('products.form.taxRatePlaceholder')}
                  helperText={t('products.form.taxRateHelp')}
                  InputProps={{
                    endAdornment: <InputAdornment position="end">%</InputAdornment>,
                  }}
                />
              </Grid>

              {/* Reference Pricing Row */}
              <Grid item xs={12} md={3}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.netContent')}
                  value={formData.netContent}
                  onChange={(e) => handleChange('netContent', e.target.value)}
                  type="number"
                  placeholder={t('products.form.netContentPlaceholder')}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <CustomDropdown
                  label={t('products.contentUnit')}
                  value={formData.contentUnit}
                  options={[
                    { value: '', label: t('products.form.contentUnitPlaceholder') },
                    { value: 'g', label: 'g' },
                    { value: 'KG', label: 'KG' },
                    { value: 'mL', label: 'mL' },
                    { value: 'L', label: 'L' },
                    { value: 'cm', label: 'cm' },
                    { value: 'M', label: 'M' },
                    { value: 'PC', label: 'PC' },
                    { value: 'PCS', label: 'PCS' },
                    { value: 'Unit', label: 'Unit' },
                  ]}
                  onChange={(value) => handleChange('contentUnit', value)}
                  fullWidth
                  size="small"
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.referencePrice')}
                  value={formData.referencePrice}
                  onChange={(e) => handleChange('referencePrice', e.target.value)}
                  type="number"
                  placeholder={t('products.form.referencePricePlaceholder')}
                  helperText={formData.referencePrice ? t('products.form.referencePriceHelp') : ''}
                  InputProps={{
                    startAdornment: <InputAdornment position="start">€</InputAdornment>,
                  }}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <CustomDropdown
                  label={t('products.referenceUnit')}
                  value={formData.referenceUnit}
                  options={[
                    { value: '', label: t('products.form.referenceUnitPlaceholder') },
                    { value: 'KG', label: 'KG' },
                    { value: 'L', label: 'L' },
                    { value: 'M', label: 'M' },
                    { value: 'PC', label: 'PC' },
                    { value: 'PCS', label: 'PCS' },
                    { value: 'Unit', label: 'Unit' },
                  ]}
                  onChange={(value) => handleChange('referenceUnit', value)}
                  fullWidth
                  size="small"
                />
              </Grid>

              {/* Logistics */}
              <Grid item xs={12}>
                <Typography variant="subtitle1" fontWeight={600} gutterBottom sx={{ mt: 2 }}>
                  {t('products.form.logistics')}
                </Typography>
              </Grid>
              <Grid item xs={6} md={2}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.form.length')}
                  value={formData.logisticsLength}
                  onChange={(e) => handleChange('logisticsLength', e.target.value)}
                  type="number"
                  placeholder="0"
                  InputProps={{
                    endAdornment: <InputAdornment position="end">cm</InputAdornment>,
                  }}
                />
              </Grid>
              <Grid item xs={6} md={2}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.form.width')}
                  value={formData.logisticsWidth}
                  onChange={(e) => handleChange('logisticsWidth', e.target.value)}
                  type="number"
                  placeholder="0"
                  InputProps={{
                    endAdornment: <InputAdornment position="end">cm</InputAdornment>,
                  }}
                />
              </Grid>
              <Grid item xs={6} md={2}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.form.height')}
                  value={formData.logisticsHeight}
                  onChange={(e) => handleChange('logisticsHeight', e.target.value)}
                  type="number"
                  placeholder="0"
                  InputProps={{
                    endAdornment: <InputAdornment position="end">cm</InputAdornment>,
                  }}
                />
              </Grid>
              <Grid item xs={6} md={3}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.form.packageWeight')}
                  value={formData.logisticsWeight}
                  onChange={(e) => handleChange('logisticsWeight', e.target.value)}
                  type="number"
                  placeholder="0"
                  InputProps={{
                    endAdornment: <InputAdornment position="end">g</InputAdornment>,
                  }}
                />
              </Grid>
              <Grid item xs={6} md={3}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.form.packageVolume')}
                  value={formData.logisticsVolume}
                  type="number"
                  placeholder="Auto-calculated"
                  InputProps={{
                    readOnly: true,
                    endAdornment: <InputAdornment position="end">cm³</InputAdornment>,
                  }}
                />
              </Grid>

              {/* Inventory */}
              <Grid item xs={12}>
                <Typography variant="subtitle1" fontWeight={600} gutterBottom sx={{ mt: 2 }}>
                  {t('products.form.inventory')}
                </Typography>
              </Grid>
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.stock')}
                  value={formData.stockLeft}
                  onChange={(e) => handleChange('stockLeft', e.target.value)}
                  type="number"
                  required
                />
              </Grid>
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.minOrderQty')}
                  value={formData.minimumOrderQuantity}
                  onChange={(e) => handleChange('minimumOrderQuantity', e.target.value)}
                  type="number"
                />
              </Grid>
              <Grid item xs={12} md={4}>
                <TextField
                  fullWidth
                  size="small"
                  label={t('products.shelfCode')}
                  value={formData.shelfCode}
                  onChange={(e) => handleChange('shelfCode', e.target.value)}
                />
              </Grid>

              {/* Product Settings */}
              {!isChildMode && (
                <>
                  <Grid item xs={12}>
                    <Typography variant="subtitle1" fontWeight={600} gutterBottom sx={{ mt: 2 }}>
                      {t('products.form.productSettings')}
                    </Typography>
                  </Grid>
                  <Grid item xs={12} md={4}>
                    <CustomDropdown
                      label={t('products.form.productType')}
                      value={formData.productType}
                      options={[
                        { value: 'standalone', label: t('products.form.productTypeStandalone') },
                        { value: 'parent', label: t('products.form.productTypeParent') },
                      ]}
                      onChange={(value) => handleChange('productType', value)}
                      fullWidth
                      size="small"
                    />
                  </Grid>
                  <Grid item xs={12} md={4}>
                    <CustomDropdown
                      label={t('products.form.visibility')}
                      value={formData.visibility}
                      options={[
                        { value: 'visible', label: t('products.form.visibilityVisible') },
                        { value: 'hidden', label: t('products.form.visibilityHidden') },
                        { value: 'featured', label: t('products.form.visibilityFeatured') },
                      ]}
                      onChange={(value) => handleChange('visibility', value)}
                      fullWidth
                      size="small"
                    />
                  </Grid>
                  {formData.productType === 'parent' && (
                    <>
                      <Grid item xs={12}>
                        <VariationOptionsEditor
                          options={formData.variationOptions}
                          onChange={(newOptions) => handleChange('variationOptions', newOptions)}
                          showPreview
                        />
                      </Grid>
                    </>
                  )}
                </>
              )}

              {/* Specifications - Amazon-style product details (Brand, Material, Country of Origin, etc.) */}
              <Grid item xs={12}>
                <Card variant="outlined" sx={{ mt: 2 }}>
                  <CardContent>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                      <Typography variant="subtitle1" fontWeight={600}>
                        {t('products.form.specifications')}
                      </Typography>
                      <Button
                        size="small"
                        startIcon={<AddIcon />}
                        onClick={addSpecification}
                      >
                        {t('products.form.addSpecification')}
                      </Button>
                    </Box>
                    {formData.specifications.length === 0 ? (
                      <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center', py: 2 }}>
                        {t('products.form.noSpecifications')}
                      </Typography>
                    ) : (
                      <Grid container spacing={2}>
                        {formData.specifications.map((spec, index) => (
                          <React.Fragment key={index}>
                            <Grid item xs={5}>
                              <TextField
                                fullWidth
                                size="small"
                                label={t('products.form.specificationName')}
                                value={spec.name}
                                onChange={(e) => updateSpecification(index, 'name', e.target.value)}
                                placeholder={t('products.form.specificationNamePlaceholder')}
                              />
                            </Grid>
                            <Grid item xs={5}>
                              <TextField
                                fullWidth
                                size="small"
                                label={t('products.form.specificationValue')}
                                value={spec.value}
                                onChange={(e) => updateSpecification(index, 'value', e.target.value)}
                                placeholder={t('products.form.specificationValuePlaceholder')}
                              />
                            </Grid>
                            <Grid item xs={2}>
                              <IconButton
                                color="error"
                                onClick={() => removeSpecification(index)}
                              >
                                <DeleteIcon />
                              </IconButton>
                            </Grid>
                          </React.Fragment>
                        ))}
                      </Grid>
                    )}
                  </CardContent>
                </Card>
              </Grid>

              {/* Images */}
              <Grid item xs={12}>
                <Card variant="outlined" sx={{ mt: 1 }}>
                  <CardContent>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                      <Typography variant="subtitle1" fontWeight={600}>
                        {t('products.images')}
                      </Typography>
                    </Box>
                    
                    {/* Hidden file input */}
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept="image/jpeg,image/png,image/gif,image/webp"
                      multiple
                      style={{ display: 'none' }}
                      onChange={(e) => handleFileSelect(e.target.files)}
                    />
                    
                    {/* Drag & Drop Upload Area */}
                    <Box
                      onDrop={handleDrop}
                      onDragOver={handleDragOver}
                      onDragLeave={handleDragLeave}
                      onClick={() => fileInputRef.current?.click()}
                      sx={{
                        border: 2,
                        borderStyle: 'dashed',
                        borderColor: dragOver ? 'primary.main' : 'grey.400',
                        borderRadius: 2,
                        p: 3,
                        mb: 2,
                        textAlign: 'center',
                        cursor: 'pointer',
                        bgcolor: dragOver ? 'action.hover' : 'background.paper',
                        transition: 'all 0.2s ease',
                        '&:hover': {
                          borderColor: 'primary.main',
                          bgcolor: 'action.hover',
                        },
                      }}
                    >
                      <CloudUploadIcon sx={{ fontSize: 48, color: 'grey.400', mb: 1 }} />
                      <Typography variant="body1" color="text.secondary">
                        {t('products.form.dragDropImages')}
                      </Typography>
                      <Typography variant="body2" color="text.disabled" sx={{ mt: 0.5 }}>
                        {t('products.form.supportedFormats')}
                      </Typography>
                    </Box>

                    {/* Image Grid */}
                    {formData.images.length > 0 && (
                      <Grid container spacing={2}>
                        {formData.images.map((img, index) => (
                          <Grid item xs={6} sm={4} md={3} key={index}>
                            <Box
                              sx={{
                                border: img.isPrimary ? 2 : 1,
                                borderColor: img.isPrimary ? 'primary.main' : 'divider',
                                borderRadius: 2,
                                overflow: 'hidden',
                                bgcolor: 'background.paper',
                                position: 'relative',
                              }}
                            >
                              {/* Square Image Preview */}
                              <Box
                                sx={{
                                  width: '100%',
                                  paddingBottom: '100%', // Creates square aspect ratio
                                  position: 'relative',
                                  bgcolor: 'grey.100',
                                  cursor: (img.url || img.previewUrl) ? 'pointer' : 'default',
                                }}
                                onClick={() => {
                                  const url = img.url || img.previewUrl;
                                  if (url) window.open(url, '_blank');
                                }}
                              >
                                {(img.url || img.previewUrl) ? (
                                  <Box
                                    component="img"
                                    src={img.url || img.previewUrl}
                                    sx={{
                                      position: 'absolute',
                                      top: 0,
                                      left: 0,
                                      width: '100%',
                                      height: '100%',
                                      objectFit: 'cover',
                                    }}
                                    onError={(e) => {
                                      (e.target as HTMLImageElement).style.display = 'none';
                                    }}
                                  />
                                ) : (
                                  <Box
                                    sx={{
                                      position: 'absolute',
                                      top: '50%',
                                      left: '50%',
                                      transform: 'translate(-50%, -50%)',
                                    }}
                                  >
                                    <ImageIcon sx={{ fontSize: 48, color: 'grey.400' }} />
                                  </Box>
                                )}
                                
                                {/* Upload Progress Overlay */}
                                {img.uploading && (
                                  <Box
                                    sx={{
                                      position: 'absolute',
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      bgcolor: 'rgba(0, 0, 0, 0.5)',
                                      display: 'flex',
                                      flexDirection: 'column',
                                      alignItems: 'center',
                                      justifyContent: 'center',
                                    }}
                                  >
                                    <CircularProgress size={32} sx={{ color: 'white', mb: 1 }} />
                                    <Typography variant="caption" sx={{ color: 'white' }}>
                                      {img.uploadProgress || 0}%
                                    </Typography>
                                  </Box>
                                )}
                                
                                {/* Primary Badge Button - top left (clickable for all images) */}
                                <Chip
                                  label={img.isPrimary ? t('products.form.primary') : t('products.form.setPrimary')}
                                  size="small"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    if (!img.isPrimary && !img.uploading) {
                                      setPrimaryImage(index);
                                    }
                                  }}
                                  sx={{
                                    position: 'absolute',
                                    top: 8,
                                    left: 8,
                                    fontSize: '0.65rem',
                                    height: 22,
                                    fontWeight: 600,
                                    cursor: img.isPrimary ? 'default' : 'pointer',
                                    ...(img.isPrimary
                                      ? {
                                          bgcolor: 'error.main',
                                          color: 'white',
                                        }
                                      : {
                                          bgcolor: 'transparent',
                                          color: 'error.main',
                                          border: '1.5px solid',
                                          borderColor: 'error.main',
                                          '&:hover': {
                                            bgcolor: 'error.main',
                                            color: 'white',
                                          },
                                        }),
                                  }}
                                />
                                
                                {/* Delete Button - top right */}
                                <IconButton
                                  size="small"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    removeImage(index);
                                  }}
                                  disabled={img.uploading}
                                  sx={{
                                    position: 'absolute',
                                    top: 4,
                                    right: 4,
                                    bgcolor: 'rgba(0, 0, 0, 0.5)',
                                    color: 'white',
                                    '&:hover': {
                                      bgcolor: 'error.main',
                                    },
                                    width: 28,
                                    height: 28,
                                  }}
                                >
                                  <DeleteIcon sx={{ fontSize: 16 }} />
                                </IconButton>
                                
                                {/* Pending Upload Badge */}
                                {img.file && !img.url && !img.uploading && (
                                  <Chip
                                    label={t('products.form.pending')}
                                    size="small"
                                    color="warning"
                                    sx={{
                                      position: 'absolute',
                                      bottom: 8,
                                      left: 8,
                                      fontSize: '0.7rem',
                                      height: 22,
                                    }}
                                  />
                                )}
                              </Box>
                            </Box>
                          </Grid>
                        ))}
                      </Grid>
                    )}
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} disabled={saving}>
          {t('common.cancel')}
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={saving || loading || !formData.title || !formData.storeId || !formData.mainPrice}
          startIcon={saving ? <CircularProgress size={16} /> : <SaveIcon />}
        >
          {saving ? t('common.saving') : t('common.save')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ProductFormModal;
