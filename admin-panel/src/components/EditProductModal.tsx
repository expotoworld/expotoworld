import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Stepper,
  Step,
  StepLabel,
  Card,
  CardContent,
  Avatar,
  IconButton,
  FormControlLabel,
  Switch,
  Autocomplete,
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  CheckCircle as SuccessIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import api, { productService, storeService, categoryService, orgService, relationshipService } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import ImageCarousel from './ImageCarousel';
import type { Product, Store, Category, Subcategory, Organization, ProductImage } from '../types/domain';

interface EditProductModalProps {
  open: boolean;
  onClose: () => void;
  product: Product | null;
  onProductUpdated: () => void;
}

interface EditProductFormData {
  title: string;
  sku: string;
  description_long: string;
  weight: string;
  mini_app_type: string;
  store_id: string | null;
  shelf_code: string;
  main_price: string;
  strikethrough_price: string;
  cost_price: string;
  stock_left: string;
  minimum_order_quantity: string;
  is_featured: boolean;
  is_mini_app_recommendation: boolean;
  is_active: boolean;
  category_ids: number[];
  subcategory_ids: number[];
  manufacturer_org_id: string;
  tpl_org_id: string;
}

interface MiniAppTypeOption {
  value: string;
  label: string;
  requiresStore: boolean;
}

const steps = ['Product Details', 'Image Management'];

const EditProductModal: React.FC<EditProductModalProps> = ({ open, onClose, product, onProductUpdated }) => {
  const { showSuccess, showError } = useToast();
  const [activeStep, setActiveStep] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Form data initialized with existing product data
  const [formData, setFormData] = useState<EditProductFormData>({
    title: '',
    sku: '',
    description_long: '',
    weight: '1',
    mini_app_type: 'ETWtoB',
    store_id: null,
    shelf_code: '',
    main_price: '',
    strikethrough_price: '',
    cost_price: '',
    stock_left: '0',
    minimum_order_quantity: '1',
    is_featured: false,
    is_mini_app_recommendation: false,
    is_active: true,
    category_ids: [],
    subcategory_ids: [],
    manufacturer_org_id: '',
    tpl_org_id: '',
  });
  // Organizations for sourcing/logistics
  const [manufacturers, setManufacturers] = useState<Organization[]>([]);
  const [tpls, setTpls] = useState<Organization[]>([]);
  const [loadingOrgs, setLoadingOrgs] = useState<boolean>(false);

  // Image management data
  const [productImages, setProductImages] = useState<ProductImage[]>([]);
  const [uploadingImages, setUploadingImages] = useState<boolean>(false);

  // Dynamic dropdown data
  const [stores, setStores] = useState<Store[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [subcategories, setSubcategories] = useState<Subcategory[]>([]);
  const [loadingStores, setLoadingStores] = useState<boolean>(false);
  const [loadingCategories, setLoadingCategories] = useState<boolean>(false);
  const [shelfCodeError, setShelfCodeError] = useState<string>('');
  const [shelfCodeChecking, setShelfCodeChecking] = useState<boolean>(false);

  const [loadingSubcategories, setLoadingSubcategories] = useState<boolean>(false);

  // ETW Mini-app type options (primary naming)
  const miniAppTypes: MiniAppTypeOption[] = [
    { value: 'ETWtoB', label: 'ETW to B', requiresStore: false },
    { value: 'ETWtoU', label: 'ETW to U', requiresStore: true },
    { value: 'ETWtoC', label: 'ETW to C', requiresStore: true },
    { value: 'ETWtoG', label: 'ETW to G', requiresStore: false },
  ];

  // Initialize form data when product changes
  useEffect(() => {
    if (!product) {
      return;
    }

    // Use etw_mini_app_type directly (backend now uses ETW values)
    const miniAppType = product.etw_mini_app_type || product.mini_app_type || 'ETWtoB';

    setFormData(prev => ({
      ...prev,
      title: product.title || '',
      sku: product.sku || '',
      description_long: product.description_long || '',
      weight: product.weight != null ? product.weight.toString() : '1',
      mini_app_type: miniAppType,
      store_id: product.store_id != null ? String(product.store_id) : null,
      shelf_code: product.shelf_code || '',
      main_price: product.main_price != null ? product.main_price.toString() : '',
      strikethrough_price:
        product.strikethrough_price != null ? product.strikethrough_price.toString() : '',
      cost_price: product.cost_price != null ? product.cost_price.toString() : '',
      stock_left: product.stock_left != null ? String(product.stock_left) : '0',
      minimum_order_quantity:
        product.minimum_order_quantity != null
          ? String(product.minimum_order_quantity)
          : '1',
      is_featured: product.is_featured || false,
      is_mini_app_recommendation: product.is_mini_app_recommendation || false,
      is_active: product.is_active !== undefined ? product.is_active : true,
      category_ids: product.category_ids || [],
      subcategory_ids: product.subcategory_ids || [],
    }));

    // Load product images
    loadProductImages(product.id);

    // Load dynamic data for the product's mini-app type
    loadStores(miniAppType);
    loadCategories(miniAppType, product.store_id ?? null);
    // Load subcategories if category is selected
    if (product.category_ids && product.category_ids.length > 0) {
      loadSubcategories(product.category_ids[0]);
    }

    // Prefill existing sourcing/logistics assignments for edit
    (async () => {
      try {
        const [sourcing, logistics] = await Promise.all([
          relationshipService.getProductSourcing(product.id).catch(() => null),
          relationshipService.getProductLogistics(product.id).catch(() => null),
        ]);
        const firstManufacturer = sourcing?.mappings?.[0]?.manufacturer_org_id || '';
        const firstTpl = logistics?.mappings?.[0]?.tpl_org_id || '';
        if (firstManufacturer || firstTpl) {
          setFormData(prev => ({
            ...prev,
            manufacturer_org_id: firstManufacturer,
            tpl_org_id: firstTpl,
          }));
        }
      } catch (e) {
        console.warn('Failed to prefill assignments', e);
      }
    })();
  }, [product]);

  const handleInputChange = (field: keyof EditProductFormData) => (event: any) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleCategoriesChange = (categoryIds: number[]) => {
    setFormData(prev => ({
      ...prev,
      category_ids: categoryIds,
      subcategory_ids: [], // Reset subcategories when categories change
    }));
    // Load subcategories for selected categories
    if (categoryIds.length > 0) {
      loadSubcategories(categoryIds[0]); // Load subcategories for first selected category
    } else {
      setSubcategories([]);
    }
  };

  const handleSubcategoriesChange = (subcategoryIds: number[]) => {
    setFormData(prev => ({
      ...prev,
      subcategory_ids: subcategoryIds,
    }));
  };

  // Load stores based on mini-app type
  const loadStores = async (miniAppType: string) => {
    if (!miniAppTypes.find(type => type.value === miniAppType)?.requiresStore) {
      setStores([]);
      return;
    }

    try {
      setLoadingStores(true);
      // Use ETW mini-app type directly (backend now uses ETW values)
      const storesData = await storeService.getStoresByMiniApp(miniAppType);
      setStores(storesData || []);
    } catch (error) {
      console.error('Error loading stores:', error);
      showError('Failed to load stores');
      setStores([]);
    } finally {
      setLoadingStores(false);
    }
  };

  // Load categories based on ETW mini-app type and store
  const loadCategories = async (miniAppType: string, storeId: number | null = null) => {
    try {
      setLoadingCategories(true);
      // Use ETW mini-app type directly (backend now uses ETW values)
      const categoriesData = await categoryService.getCategoriesByMiniApp(
        miniAppType,
        storeId,
      );
      setCategories(categoriesData.categories || []);
    } catch (error) {
      console.error('Error loading categories:', error);
      showError('Failed to load categories');
      setCategories([]);
    } finally {
      setLoadingCategories(false);
    }
  };

  // Load organizations for Step 1 (assignments live in Step 1 of Edit modal)
  useEffect(() => {
    if (!open) return;
    if (activeStep !== 0) return;
    let cancelled = false;
    (async () => {
      try {
        setLoadingOrgs(true);
        const [m, l] = await Promise.all([
          orgService.getOrganizations('Manufacturer'),
          orgService.getOrganizations('3PL'),
        ]);
        if (!cancelled) {
          setManufacturers(m?.organizations || []);
          setTpls(l?.organizations || []);
        }
      } catch (e) {
        console.error('Failed to load organizations', e);
      } finally {
        if (!cancelled) setLoadingOrgs(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [open, activeStep]);

  const loadSubcategories = async (categoryId: number) => {
    try {
      setLoadingSubcategories(true);
      const subcategoriesData = await categoryService.getSubcategories(categoryId);
      setSubcategories(subcategoriesData.subcategories || []);
    } catch (error) {
      console.error('Error loading subcategories:', error);
      showError('Failed to load subcategories');
      setSubcategories([]);
    } finally {
      setLoadingSubcategories(false);
    }
  };

  // Handle mini-app type change
  const handleMiniAppTypeChange = (event: any) => {
    const newMiniAppType = event.target.value as string;
    setFormData(prev => ({
      ...prev,
      mini_app_type: newMiniAppType,
      store_id: null,
      category_ids: [],
      subcategory_ids: [],
    }));

    // Load stores if required
    loadStores(newMiniAppType);
    // Load categories for new mini-app type
    loadCategories(newMiniAppType);
    // Clear subcategories
    setSubcategories([]);
  };

  // Handle store selection change
  const handleStoreChange = (event: any) => {
    const newStoreId = event.target.value as string;
    setFormData(prev => ({
      ...prev,
      store_id: newStoreId,
      category_ids: [],
      subcategory_ids: [],
    }));

    const numericStoreId = newStoreId ? parseInt(newStoreId, 10) : null;

    // Reload categories for new store
    loadCategories(formData.mini_app_type, numericStoreId);
    // Clear subcategories
    setSubcategories([]);
  };

  // Real-time shelf code validation (debounced)
  useEffect(() => {
    const requiresStore = ['ETWtoU', 'ETWtoC'].includes(formData.mini_app_type);
    if (!requiresStore || !formData.store_id) {
      setShelfCodeError('');
      return;
    }

    const code = (formData.shelf_code || '').trim();
    if (!code) {
      setShelfCodeError('');
      return;
    }

    setShelfCodeChecking(true);
    const t = setTimeout(async () => {
      try {
        const storeIdForValidation = formData.store_id ? parseInt(formData.store_id, 10) : null;
        if (!storeIdForValidation) {
          setShelfCodeError('');
          return;
        }

        const result = await productService.validateShelfCode({
          store_id: storeIdForValidation,
          shelf_code: code,
          product_id: product?.id ?? null,
        });
        if (result && result.valid === false) {
          setShelfCodeError('Shelf code already exists for this store');
        } else {
          setShelfCodeError('');
        }
      } catch (e) {
        setShelfCodeError('');
      } finally {
        setShelfCodeChecking(false);
      }
    }, 600);
    return () => clearTimeout(t);
  }, [formData.mini_app_type, formData.store_id, formData.shelf_code, product?.id]);


  const handleStep1Submit = async (): Promise<void> => {
    try {
      setLoading(true);
      setError(null);

      if (!product) {
        setError('Product not found');
        return;
      }

      // Validate required fields
      if (!formData.title || !formData.sku || !formData.main_price || !formData.weight) {
        throw new Error('Please fill in all required fields');
      }

      // Validate weight >= 1 gram
      const weightVal = parseFloat(formData.weight);
      if (Number.isNaN(weightVal) || weightVal < 1) {
        throw new Error('Product weight must be at least 1 gram');
      }

      // Validate mini-app specific requirements
      const selectedMiniAppType = miniAppTypes.find(type => type.value === formData.mini_app_type);
      if (selectedMiniAppType?.requiresStore && !formData.store_id) {
        throw new Error('Please select a store for this mini-app type');
      }
      if (selectedMiniAppType?.requiresStore && formData.store_id) {
        const code = (formData.shelf_code || '').trim();
        if (!code) {
          throw new Error('Please enter a shelf code');
        }
        if (shelfCodeError) {
          throw new Error('Shelf code must be unique for the selected store');
        }
      }

      // Determine etw_store_type from selected store for store-based mini-apps
      let etwStoreType: string | null = null;
      if (formData.mini_app_type === 'ETWtoU' || formData.mini_app_type === 'ETWtoC') {
        const selectedStore = stores.find(s => s.id === parseInt(formData.store_id as string, 10));
        etwStoreType = selectedStore?.etw_store_type ?? null;
      }

      // Prepare data for API
      const requiresStore = miniAppTypes.find(t => t.value === formData.mini_app_type)?.requiresStore;
      const productData: Record<string, unknown> = {
        ...formData,
        main_price: parseFloat(formData.main_price),
        strikethrough_price: formData.strikethrough_price
          ? parseFloat(formData.strikethrough_price)
          : null,
        cost_price: formData.cost_price
          ? parseFloat(formData.cost_price)
          : null,
        weight: formData.weight ? parseFloat(formData.weight) : 1,
        stock_left:
          formData.mini_app_type === 'ETWtoU' ? (parseInt(formData.stock_left, 10) || 0) : undefined,
        minimum_order_quantity: parseInt(formData.minimum_order_quantity, 10) || 1,
        etw_mini_app_type: formData.mini_app_type, // Use ETW type directly
        etw_store_type: etwStoreType,
        store_id: formData.store_id ? parseInt(formData.store_id, 10) : null,
        shelf_code:
          requiresStore && formData.store_id ? (formData.shelf_code?.trim() || null) : null,
        is_active: formData.is_active,
        category_ids: formData.category_ids,
        subcategory_ids: formData.subcategory_ids,
        // Main page featured only for ETWtoU and ETWtoC
        is_featured: ['ETWtoU', 'ETWtoC'].includes(formData.mini_app_type)
          ? formData.is_featured
          : false,
        is_mini_app_recommendation: formData.is_mini_app_recommendation,
      };

      // Call the real API to update the product
      await productService.updateProduct(product.id, productData as any);

      // Apply sourcing/logistics assignments (non-blocking)
      try {
        const numericStoreId = formData.store_id ? parseInt(formData.store_id, 10) : null;
        const selectedStore = stores.find(s => s.id === numericStoreId);
        const regionId = selectedStore?.region_id || null;
        const promises: Promise<unknown>[] = [];
        if (formData.manufacturer_org_id && regionId) {
          promises.push(
            relationshipService.manageProductSourcing(product.id, [
              { region_id: regionId, manufacturer_org_id: formData.manufacturer_org_id },
            ]),
          );
        }
        if (formData.tpl_org_id) {
          promises.push(
            relationshipService.manageProductLogistics(product.id, [
              { tpl_org_id: formData.tpl_org_id },
            ]),
          );
        }
        if (promises.length) await Promise.all(promises);
      } catch (e) {
        console.warn('Assignments update failed (non-blocking):', e);
      }

      showSuccess('Product details updated successfully!');

      // Move to step 2 after success
      setTimeout(() => {
        setActiveStep(1);
      }, 1000);
    } catch (err: unknown) {
      console.error('Error updating product:', err);
      const message = err instanceof Error ? err.message : 'Failed to update product';
      setError(message);
    } finally {
      setLoading(false);
    }
  };



  // Load product images
  const loadProductImages = async (productId: number): Promise<void> => {
    try {
      const { data } = await api.get(`/products/${productId}/images`);
      const images = (data as any).images ?? data;
      setProductImages(images as ProductImage[]);
    } catch (error) {
      console.error('Error loading product images:', error);
    }
  };

  // Handle multiple image upload
  const handleMultipleImageUpload = async (files: File[]): Promise<void> => {
    if (!product?.id) {
      showError('Product ID not available');
      return;
    }

    try {
      setUploadingImages(true);
      const formData = new FormData();

      files.forEach(file => {
        formData.append('images', file);
      });

      const { data } = await api.post(`/products/${product.id}/images`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const images = (data as any).images ?? [];
      setProductImages(prev => [...prev, ...(images as ProductImage[])]);
      showSuccess(`${(images as ProductImage[]).length} image(s) uploaded successfully`);
    } catch (error) {
      console.error('Error uploading images:', error);
      showError('Failed to upload images');
    } finally {
      setUploadingImages(false);
    }
  };

  // Handle image deletion
  const handleImageDelete = async (imageId: number): Promise<void> => {
    if (!product?.id) return;

    try {
      await api.delete(`/products/${product.id}/images/${imageId}`);
      setProductImages(prev => prev.filter(img => img.id !== imageId));
      showSuccess('Image deleted successfully');
    } catch (error) {
      console.error('Error deleting image:', error);
      showError('Failed to delete image');
    }
  };

  // Handle image reordering
  const handleImageReorder = async (reorderedImages: ProductImage[]): Promise<void> => {
    if (!product?.id) return;

    try {
      const imageOrders = reorderedImages.map((img, index) => ({
        image_id: img.id,
        display_order: index + 1,
      }));

      await api.put(`/products/${product.id}/images/reorder`, { image_orders: imageOrders });
      setProductImages(reorderedImages);
      showSuccess('Images reordered successfully');
    } catch (error) {
      console.error('Error reordering images:', error);
      showError('Failed to reorder images');
    }
  };

  // Handle setting primary image
  const handleSetPrimaryImage = async (imageId: number): Promise<void> => {
    if (!product?.id) return;

    try {
      await api.put(`/products/${product.id}/images/${imageId}/primary`);
      setProductImages(prev => prev.map(img => ({
        ...img,
        is_primary: img.id === imageId,
      })));
      showSuccess('Primary image set successfully');
    } catch (error) {
      console.error('Error setting primary image:', error);
      showError('Failed to set primary image');
    }
  };

  const handleClose = () => {
    // Reset form state
    setActiveStep(0);
    setProductImages([]);
    setUploadingImages(false);
    setStores([]);
    setCategories([]);
    setSubcategories([]);
    setError(null);
    setSuccess(null);
    setLoading(false);

    onClose();
  };



  if (!product) return null;

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: '12px' }
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            Edit Product
          </Typography>
          <IconButton onClick={handleClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>



        <Stepper activeStep={activeStep} sx={{ mt: 2 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
      </DialogTitle>

      <DialogContent sx={{ pt: 6, pb: 2 }}>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {success && (
          <Alert severity="success" sx={{ mb: 2 }}>
            {success}
          </Alert>
        )}

        {/* Step 1: Edit Product Details */}
        {activeStep === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 2 }}>
            <TextField
              label="Product Title *"
              value={formData.title}
              onChange={handleInputChange('title')}
              fullWidth
              disabled={loading}
            />

            <TextField
              label="SKU *"
              value={formData.sku}
              onChange={handleInputChange('sku')}
              fullWidth
              disabled={loading}
              helperText="Unique product identifier"
            />

            <TextField
              label="Product Description"
              value={formData.description_long}
              onChange={handleInputChange('description_long')}
              fullWidth
              multiline
              rows={3}
              disabled={loading}
              helperText="Detailed description for product"
            />

            <TextField
              label="Product Weight (grams) *"
              value={formData.weight}
              onChange={handleInputChange('weight')}
              type="number"
              inputProps={{ step: '0.01', min: '1' }}
              fullWidth
              disabled={loading}
              helperText="grams"
            />


            <FormControl fullWidth disabled={loading}>
              <InputLabel>Mini-APP Type *</InputLabel>
              <Select
                value={formData.mini_app_type}
                onChange={handleMiniAppTypeChange}
                label="Mini-APP Type *"
              >
                {miniAppTypes.map((type) => (
                  <MenuItem key={type.value} value={type.value}>
                    {type.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {/* Conditional Store Selection */}
            {miniAppTypes.find(type => type.value === formData.mini_app_type)?.requiresStore && (
              <FormControl fullWidth disabled={loading || loadingStores}>
                <InputLabel>Store Location *</InputLabel>
                <Select
                  value={formData.store_id || ''}
                  onChange={handleStoreChange}
                  label="Store Location *"
                >
                  {stores.map((store) => (
                    <MenuItem key={store.id} value={store.id}>
                      {store.name} - {store.city}
                    </MenuItem>
                  ))}
                </Select>
                {loadingStores && (
                  <Typography variant="caption" sx={{ mt: 1, color: 'text.secondary' }}>
                    Loading stores...
                  </Typography>
                )}
              </FormControl>
            )}



            {/* Pricing Section */}
            <Typography variant="h6" sx={{ mt: 2, mb: 1 }}>Pricing & Inventory</Typography>

            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                label="Main Price *"
                value={formData.main_price}
                onChange={handleInputChange('main_price')}
                type="number"
                inputProps={{ step: '0.01', min: '0' }}
                fullWidth
                disabled={loading}
              />

              <TextField
                label="Strikethrough Price"
                value={formData.strikethrough_price}
                onChange={handleInputChange('strikethrough_price')}
                type="number"
                inputProps={{ step: '0.01', min: '0' }}
                fullWidth
                disabled={loading}
                helperText="Optional original price"
              />

              <TextField
                label="Cost Price"
                value={formData.cost_price}
                onChange={handleInputChange('cost_price')}
                type="number"
                inputProps={{ step: '0.01', min: '0' }}
                fullWidth
                disabled={loading}
                helperText="Manufacturer price (admin only)"
              />
            </Box>

            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                label="Stock Quantity"
                value={formData.stock_left}
                onChange={handleInputChange('stock_left')}
                type="number"
                inputProps={{ min: '0' }}
                fullWidth
                disabled={loading || formData.mini_app_type !== 'ETWtoU'}
                helperText="Available inventory (only for ETW to U)"
              />

              <TextField
                label="Minimum Order Quantity *"
                value={formData.minimum_order_quantity}
                onChange={handleInputChange('minimum_order_quantity')}
                type="number"
                inputProps={{ min: '1' }}
                fullWidth
                disabled={loading}
                helperText="Minimum order quantity"
              />
            </Box>

            {/* Dynamic Category Selection */}
            <FormControl fullWidth disabled={loading || loadingCategories}>
              <InputLabel>Category *</InputLabel>
              <Select
                value={formData.category_ids[0] || ''}
                onChange={(e) => handleCategoriesChange(e.target.value ? [Number(e.target.value)] : [])}
                label="Category *"
              >
                {categories.map((category) => (
                  <MenuItem key={category.id} value={category.id.toString()}>
                    {category.name}
                  </MenuItem>
                ))}
              </Select>
              {loadingCategories && (
                <Typography variant="caption" sx={{ mt: 1, color: 'text.secondary' }}>
                  Loading categories...
                </Typography>
              )}
            </FormControl>

            {/* Dynamic Subcategory Selection */}
            {subcategories.length > 0 && (
              <FormControl fullWidth disabled={loading || loadingSubcategories}>
                <InputLabel>Subcategory</InputLabel>
                <Select
                  value={formData.subcategory_ids[0] || ''}
                  onChange={(e) => handleSubcategoriesChange(e.target.value ? [Number(e.target.value)] : [])}
                  label="Subcategory"
                >
                  {subcategories.map((subcategory) => (
                    <MenuItem key={subcategory.id} value={subcategory.id.toString()}>
                      {subcategory.name}
                    </MenuItem>
                  ))}
                </Select>
                {loadingSubcategories && (
                  <Typography variant="caption" sx={{ mt: 1, color: 'text.secondary' }}>
                    Loading subcategories...
                  </Typography>
                )}
              </FormControl>
            )}


            {/* Shelf Code (only for store-based mini-apps) */}
            {miniAppTypes.find(type => type.value === formData.mini_app_type)?.requiresStore && formData.store_id && (
              <TextField
                label="Shelf Code"
                value={formData.shelf_code}
                onChange={handleInputChange('shelf_code')}
                required
                inputProps={{ maxLength: 50 }}
                fullWidth
                disabled={loading}
                error={Boolean(shelfCodeError)}
                helperText={
                  shelfCodeError
                    ? shelfCodeError
                    : (shelfCodeChecking
                        ? 'Checking...'
                        : ((formData.shelf_code || '').trim() ? 'Available • Unique per store' : 'Unique per store'))
                }
                FormHelperTextProps={{
                  sx: { color: shelfCodeError ? 'error.main' : (shelfCodeChecking ? 'text.secondary' : 'success.main') }
                }}
              />
            )}

            {/* Main Page Featured Toggle - Only for ETWtoU and ETWtoC */}
            {['ETWtoU', 'ETWtoC'].includes(formData.mini_app_type) && (
              <Box sx={{ mt: 2 }}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.is_featured}
                      onChange={handleInputChange('is_featured')}
                      disabled={loading}
                      color="secondary"
                    />
                  }
                  label={
                    <Box>
                      <Typography variant="body1" sx={{ fontWeight: 500 }}>
                        Add to 热门推荐 (Main Page Featured)
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Featured products appear prominently in the main app
                      </Typography>
                    </Box>
                  }
                  sx={{ alignItems: 'flex-start' }}
                />
              </Box>
            )}

            {/* Mini-App Recommendation Toggle - For all mini-apps */}
            <Box sx={{ mt: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_mini_app_recommendation}
                    onChange={handleInputChange('is_mini_app_recommendation')}
                    disabled={loading}
                    color="primary"
                  />
                }
                label={
                  <Box>
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      Mini-App Recommendation
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Product appears in the recommendation section of the {formData.mini_app_type} mini-app
                    </Typography>
                  </Box>
                }
                sx={{ alignItems: 'flex-start' }}
              />
            </Box>

            {/* Product Status Toggle */}
            <Box sx={{ mt: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_active}
                    onChange={handleInputChange('is_active')}
                    disabled={loading}
                    color="primary"
                  />
                }
                label={
                  <Box>
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      Product Status
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {formData.is_active ? 'Active - Visible to customers' : 'Inactive - Hidden from customers'}
                    </Typography>
                  </Box>
                }
                sx={{ alignItems: 'flex-start' }}
              />
            </Box>

            {/* Organization Assignments */}
            <Typography variant="h6" sx={{ mt: 3, mb: 1 }}>Organization Assignments</Typography>

            <Autocomplete
              options={manufacturers}
              getOptionLabel={(option) => option?.name || ''}
              loading={loadingOrgs}
              value={manufacturers.find(o => String(o.org_id) === formData.manufacturer_org_id) || null}
              onChange={(_, newValue) => setFormData(prev => ({
                ...prev,
                manufacturer_org_id: newValue ? String(newValue.org_id) : '',
              }))}
              renderInput={(params) => (
                <TextField {...params} label="Manufacturer" placeholder="Search manufacturers..." fullWidth />
              )}
              disabled={loading}
            />

            <Box sx={{ mt: 2 }} />

            <Autocomplete
              options={tpls}
              getOptionLabel={(option) => option?.name || ''}
              loading={loadingOrgs}
              value={tpls.find(o => String(o.org_id) === formData.tpl_org_id) || null}
              onChange={(_, newValue) => setFormData(prev => ({
                ...prev,
                tpl_org_id: newValue ? String(newValue.org_id) : '',
              }))}
              renderInput={(params) => (
                <TextField {...params} label="3PL" placeholder="Search 3PL organizations..." fullWidth />
              )}
              disabled={loading}
            />

          </Box>
        )}

        {/* Step 2: Image Management */}
        {activeStep === 1 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Typography variant="h6" sx={{ fontWeight: 600 }}>
              Product Images
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Manage product images. Upload multiple images, reorder them, and set the primary image.
            </Typography>

            <ImageCarousel
              images={productImages}
              onImageUpload={handleMultipleImageUpload}
              onImageDelete={handleImageDelete}
              onImageReorder={handleImageReorder}
              onSetPrimary={handleSetPrimaryImage}
              loading={uploadingImages}
              maxImages={10}
            />
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 3, pt: 1 }}>
        <Button onClick={handleClose} disabled={loading}>
          Cancel
        </Button>

        {/* Back Button (for step 2) */}
        {activeStep > 0 && (
          <Button
            onClick={() => setActiveStep(activeStep - 1)}
            disabled={loading}
          >
            Back
          </Button>
        )}

        {activeStep === 0 ? (
          <Button
            variant="contained"
            onClick={handleStep1Submit}
            disabled={loading || !formData.title || !formData.sku || !formData.main_price || !formData.weight}
            startIcon={loading ? <CircularProgress size={20} /> : null}
          >
            {loading ? 'Updating...' : 'Update & Continue'}
          </Button>
        ) : (
          <Button
            variant="contained"
            onClick={() => {
              showSuccess('Product updated successfully!');
              onProductUpdated();
              handleClose();
            }}
            disabled={loading || uploadingImages}
            color="success"
          >
            Complete Update
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default EditProductModal;
