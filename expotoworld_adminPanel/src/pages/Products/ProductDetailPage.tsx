import React, { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Button,
  Typography,
  Chip,
  Grid,
  Avatar,
  IconButton,
  Tooltip,
  CircularProgress,
  Alert,
  Divider,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  ArrowBack as BackIcon,
  Star as FeaturedIcon,
  Inventory as InventoryIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as HiddenIcon,
  Sync as SyncIcon,
  Add as AddIcon,
  CheckCircle as DefaultIcon,
  Restore as RestoreIcon,
} from '@mui/icons-material';
import { PageHeader, ConfirmDialog } from '@components/common';
import {
  productApi,
  categoryApi,
  storeApi,
  type ProductWithChildren,
  type Category,
  type Store,
} from '@/services/catalogApi';

const ProductDetailPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();

  // Data state
  const [product, setProduct] = useState<ProductWithChildren | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [stores, setStores] = useState<Store[]>([]);

  // UI state
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [selectedImageIndex, setSelectedImageIndex] = useState(0);

  // Dialog states
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [syncingAggregates, setSyncingAggregates] = useState(false);
  const [settingDefaultVariant, setSettingDefaultVariant] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [unarchiving, setUnarchiving] = useState(false);

  // Fetch product
  const fetchProduct = useCallback(async () => {
    if (!id) return;

    setLoading(true);
    setError(null);
    try {
      const productData = await productApi.getProduct(id);
      
      // If it's a parent product, fetch children
      if (productData.productType === 'parent') {
        const withChildren = await productApi.getProductChildren(id);
        setProduct(withChildren);
      } else {
        setProduct(productData as ProductWithChildren);
      }
    } catch (err) {
      console.error('Failed to fetch product:', err);
      setError(t('products.fetchError'));
    } finally {
      setLoading(false);
    }
  }, [id, t]);

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

  useEffect(() => {
    fetchProduct();
    fetchReferenceData();
  }, [fetchProduct, fetchReferenceData]);

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getCategoryName = (categoryId: string) => {
    return categories.find((c) => c.id === categoryId)?.name || categoryId || '-';
  };

  const getStoreName = (storeId: string) => {
    return stores.find((s) => s.id === storeId)?.name || storeId || '-';
  };

  // Handle archive
  const handleArchive = async () => {
    if (!id) return;
    
    setDeleting(true);
    try {
      await productApi.archiveProduct(id);
      setSuccess(t('products.archiveSuccess'));
      setDeleteDialogOpen(false);
      // Refresh product data
      await fetchProduct();
    } catch (err) {
      console.error('Failed to archive product:', err);
      setError(t('products.archiveError'));
    } finally {
      setDeleting(false);
    }
  };

  // Handle unarchive
  const handleUnarchive = async () => {
    if (!id) return;
    
    setUnarchiving(true);
    try {
      await productApi.unarchiveProduct(id);
      setSuccess(t('products.unarchiveSuccess'));
      // Refresh product data
      await fetchProduct();
    } catch (err) {
      console.error('Failed to unarchive product:', err);
      setError(t('products.unarchiveError'));
    } finally {
      setUnarchiving(false);
    }
  };

  // Handle sync aggregates
  const handleSyncAggregates = async () => {
    if (!id) return;
    
    setSyncingAggregates(true);
    try {
      await productApi.syncParentAggregates(id);
      setSuccess(t('products.syncSuccess'));
      // Refresh product data
      await fetchProduct();
    } catch (err) {
      console.error('Failed to sync aggregates:', err);
      setError(t('products.syncError'));
    } finally {
      setSyncingAggregates(false);
    }
  };

  // Handle set default variant
  const handleSetDefaultVariant = async (childId: string) => {
    setSettingDefaultVariant(childId);
    try {
      await productApi.setDefaultVariant(childId);
      setSuccess(t('products.setDefaultSuccess'));
      // Refresh product data
      await fetchProduct();
    } catch (err) {
      console.error('Failed to set default variant:', err);
      setError(t('products.setDefaultError'));
    } finally {
      setSettingDefaultVariant(null);
    }
  };

  const breadcrumbs = [
    { label: t('nav.products'), path: '/products' },
    { label: product?.name || t('products.detail') },
  ];

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (!product) {
    return (
      <Box>
        <Alert severity="error">{t('products.notFound')}</Alert>
        <Button startIcon={<BackIcon />} onClick={() => navigate('/products')} sx={{ mt: 2 }}>
          {t('common.back')}
        </Button>
      </Box>
    );
  }

  return (
    <Box>
      {/* Page Header */}
      <PageHeader
        title={product.name}
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
            {product.isArchived ? (
              <Button
                variant="outlined"
                color="success"
                startIcon={unarchiving ? <CircularProgress size={16} /> : <RestoreIcon />}
                onClick={handleUnarchive}
                disabled={unarchiving}
              >
                {t('products.unarchive')}
              </Button>
            ) : (
              <>
                <Button
                  variant="outlined"
                  startIcon={<EditIcon />}
                  onClick={() => navigate(`/products/${id}/edit`)}
                >
                  {t('common.edit')}
                </Button>
                <Button
                  variant="outlined"
                  color="error"
                  startIcon={<DeleteIcon />}
                  onClick={() => setDeleteDialogOpen(true)}
                >
                  {t('common.delete')}
                </Button>
              </>
            )}
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

      {/* Archived Banner */}
      {product.isArchived && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          {t('products.archivedBanner')}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Left Column - Images */}
        <Grid item xs={12} md={5}>
          <Card elevation={0}>
            <CardContent>
              {/* Main Image */}
              <Box
                sx={{
                  width: '100%',
                  aspectRatio: '1',
                  bgcolor: 'action.hover',
                  borderRadius: 2,
                  mb: 2,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  overflow: 'hidden',
                }}
              >
                {product.imageUrls && product.imageUrls.length > 0 ? (
                  <img
                    src={product.imageUrls[selectedImageIndex]}
                    alt={product.name}
                    style={{ width: '100%', height: '100%', objectFit: 'contain' }}
                  />
                ) : (
                  <InventoryIcon sx={{ fontSize: 120, color: 'text.disabled' }} />
                )}
              </Box>
              
              {/* Thumbnail Gallery */}
              {product.imageUrls && product.imageUrls.length > 1 && (
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                  {product.imageUrls.map((url, index) => (
                    <Box
                      key={index}
                      onClick={() => setSelectedImageIndex(index)}
                      sx={{
                        width: 64,
                        height: 64,
                        borderRadius: 1,
                        overflow: 'hidden',
                        cursor: 'pointer',
                        border: '2px solid',
                        borderColor: selectedImageIndex === index ? 'primary.main' : 'transparent',
                        '&:hover': {
                          borderColor: 'primary.light',
                        },
                      }}
                    >
                      <img
                        src={url}
                        alt={`${product.name} ${index + 1}`}
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      />
                    </Box>
                  ))}
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Right Column - Details */}
        <Grid item xs={12} md={7}>
          <Card elevation={0} sx={{ mb: 3 }}>
            <CardContent>
              {/* Status Chips */}
              <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
                <Chip
                  label={product.isActive ? t('common.active') : t('common.inactive')}
                  color={product.isActive ? 'success' : 'default'}
                  size="small"
                />
                {product.isFeatured && (
                  <Chip
                    icon={<FeaturedIcon />}
                    label={t('products.featured')}
                    color="warning"
                    size="small"
                  />
                )}
                {product.productType && (
                  <Chip
                    label={t(`products.form.type${product.productType.charAt(0).toUpperCase() + product.productType.slice(1)}`)}
                    variant="outlined"
                    size="small"
                  />
                )}
                {product.visibility === 'visible' ? (
                  <Chip icon={<VisibilityIcon />} label={t('products.form.visibilityVisible')} variant="outlined" size="small" />
                ) : (
                  <Chip icon={<HiddenIcon />} label={t('products.form.visibilityHidden')} variant="outlined" size="small" />
                )}
              </Box>

              {/* Title and Description */}
              <Typography variant="h5" fontWeight={600} gutterBottom>
                {product.name}
              </Typography>
              {product.description && (
                <Typography variant="body1" color="text.secondary" paragraph>
                  {product.description}
                </Typography>
              )}

              <Divider sx={{ my: 2 }} />

              {/* Price Information */}
              <Box sx={{ mb: 2 }}>
                <Typography variant="h4" color="primary" fontWeight={700}>
                  {formatCurrency(product.currentPrice)}
                </Typography>
                {product.originalPrice !== product.currentPrice && (
                  <Typography variant="body1" color="text.secondary" sx={{ textDecoration: 'line-through' }}>
                    {formatCurrency(product.originalPrice)}
                  </Typography>
                )}
                {product.costPrice && (
                  <Typography variant="caption" color="text.secondary">
                    {t('products.form.costPrice')}: {formatCurrency(product.costPrice)}
                  </Typography>
                )}
              </Box>

              {/* Parent Product Price Range */}
              {product.productType === 'parent' && (product.priceMin || product.priceMax) && (
                <Box sx={{ mb: 2, p: 2, bgcolor: 'action.hover', borderRadius: 1 }}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.detail.priceRange')}
                  </Typography>
                  <Typography variant="h6">
                    {formatCurrency(product.priceMin || 0)} - {formatCurrency(product.priceMax || 0)}
                  </Typography>
                </Box>
              )}

              <Divider sx={{ my: 2 }} />

              {/* Product Details */}
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.form.sku')}
                  </Typography>
                  <Typography variant="body1">{product.sku || '-'}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.shelfCode')}
                  </Typography>
                  <Typography variant="body1">{product.shelfCode || '-'}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.stock')}
                  </Typography>
                  <Chip
                    label={product.stockLeft}
                    size="small"
                    color={product.stockLeft === 0 ? 'error' : product.stockLeft < 10 ? 'warning' : 'default'}
                  />
                  {product.productType === 'parent' && product.stockTotal !== undefined && (
                    <Typography variant="caption" color="text.secondary" display="block">
                      {t('products.detail.totalStock')}: {product.stockTotal}
                    </Typography>
                  )}
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.minOrderQty')}
                  </Typography>
                  <Typography variant="body1">{product.minimumOrderQuantity}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.form.weight')}
                  </Typography>
                  <Typography variant="body1">{product.weight ? `${product.weight}g` : '-'}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.category')}
                  </Typography>
                  <Typography variant="body1">{getCategoryName(product.categoryId)}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.store')}
                  </Typography>
                  <Typography variant="body1">{getStoreName(product.storeId)}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.form.organizationId')}
                  </Typography>
                  <Typography variant="body1" sx={{ fontSize: '0.75rem', wordBreak: 'break-all' }}>
                    {product.organizationId || '-'}
                  </Typography>
                </Grid>
              </Grid>

              <Divider sx={{ my: 2 }} />

              {/* Timestamps */}
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.detail.createdAt')}
                  </Typography>
                  <Typography variant="body2">{formatDate(product.createdAt)}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    {t('products.detail.updatedAt')}
                  </Typography>
                  <Typography variant="body2">{formatDate(product.updatedAt)}</Typography>
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* Attributes */}
          {product.attributes && product.attributes.length > 0 && (
            <Card elevation={0} sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  {t('products.form.attributes')}
                </Typography>
                <TableContainer>
                  <Table size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>{t('products.form.attributeName')}</TableCell>
                        <TableCell>{t('products.form.attributeValue')}</TableCell>
                        <TableCell align="center">{t('products.form.variantDefining')}</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {product.attributes.map((attr) => (
                        <TableRow key={attr.id}>
                          <TableCell>{attr.attributeName}</TableCell>
                          <TableCell>{attr.attributeValue}</TableCell>
                          <TableCell align="center">
                            {attr.isVariantDefining && <DefaultIcon color="success" fontSize="small" />}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </CardContent>
            </Card>
          )}
        </Grid>
      </Grid>

      {/* Variants Section (for parent products) */}
      {product.productType === 'parent' && (
        <Card elevation={0} sx={{ mt: 3 }}>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6">
                {t('products.detail.variants')} ({product.children?.length || 0})
              </Typography>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <Button
                  size="small"
                  startIcon={syncingAggregates ? <CircularProgress size={16} /> : <SyncIcon />}
                  onClick={handleSyncAggregates}
                  disabled={syncingAggregates}
                >
                  {t('products.detail.syncAggregates')}
                </Button>
                <Button
                  size="small"
                  variant="contained"
                  startIcon={<AddIcon />}
                  onClick={() => navigate(`/products/new?parentId=${id}`)}
                >
                  {t('products.detail.addVariant')}
                </Button>
              </Box>
            </Box>

            {product.children && product.children.length > 0 ? (
              <TableContainer component={Paper} variant="outlined">
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>{t('products.productName')}</TableCell>
                      <TableCell>{t('products.form.sku')}</TableCell>
                      <TableCell align="right">{t('products.price')}</TableCell>
                      <TableCell align="center">{t('products.stock')}</TableCell>
                      <TableCell align="center">{t('products.detail.default')}</TableCell>
                      <TableCell align="center">{t('common.actions')}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {product.children.map((child) => (
                      <TableRow
                        key={child.id}
                        hover
                        sx={{ cursor: 'pointer' }}
                        onClick={() => navigate(`/products/${child.id}`)}
                      >
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                            <Avatar
                              variant="rounded"
                              src={child.imageUrls[0]}
                              sx={{ width: 40, height: 40 }}
                            >
                              <InventoryIcon />
                            </Avatar>
                            {child.name}
                          </Box>
                        </TableCell>
                        <TableCell>{child.sku || '-'}</TableCell>
                        <TableCell align="right">{formatCurrency(child.currentPrice)}</TableCell>
                        <TableCell align="center">
                          <Chip
                            label={child.stockLeft}
                            size="small"
                            color={child.stockLeft === 0 ? 'error' : child.stockLeft < 10 ? 'warning' : 'default'}
                          />
                        </TableCell>
                        <TableCell align="center">
                          {child.isDefaultVariant ? (
                            <Chip
                              icon={<DefaultIcon />}
                              label={t('products.detail.default')}
                              size="small"
                              color="primary"
                            />
                          ) : (
                            <Button
                              size="small"
                              onClick={(e) => {
                                e.stopPropagation();
                                handleSetDefaultVariant(child.id);
                              }}
                              disabled={settingDefaultVariant === child.id}
                            >
                              {settingDefaultVariant === child.id ? (
                                <CircularProgress size={16} />
                              ) : (
                                t('products.detail.setDefault')
                              )}
                            </Button>
                          )}
                        </TableCell>
                        <TableCell align="center">
                          <Tooltip title={t('common.edit')}>
                            <IconButton
                              size="small"
                              onClick={(e) => {
                                e.stopPropagation();
                                navigate(`/products/${child.id}/edit`);
                              }}
                            >
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            ) : (
              <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center', py: 4 }}>
                {t('products.detail.noVariants')}
              </Typography>
            )}
          </CardContent>
        </Card>
      )}

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('products.deleteTitle')}
        message={t('products.deleteMessage', { name: product.name })}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleArchive}
        onCancel={() => setDeleteDialogOpen(false)}
        loading={deleting}
      />
    </Box>
  );
};

export default ProductDetailPage;
