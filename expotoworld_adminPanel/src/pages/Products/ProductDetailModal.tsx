import React, { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
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
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Star as FeaturedIcon,
  Inventory as InventoryIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as HiddenIcon,
  Sync as SyncIcon,
  Add as AddIcon,
  CheckCircle as DefaultIcon,
  Restore as RestoreIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { ConfirmDialog } from '@components/common';
import {
  productApi,
  categoryApi,
  storeApi,
  type ProductWithChildren,
  type Category,
  type Store,
} from '@/services/catalogApi';

interface ProductDetailModalProps {
  open: boolean;
  productId: string | null;
  onClose: () => void;
  onEdit: (productId: string) => void;
  onAddVariant: (parentId: string) => void;
  onRefresh: () => void;
}

const ProductDetailModal: React.FC<ProductDetailModalProps> = ({
  open,
  productId,
  onClose,
  onEdit,
  onAddVariant,
  onRefresh,
}) => {
  const { t } = useTranslation();

  // State
  const [product, setProduct] = useState<ProductWithChildren | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  
  // Reference data
  const [categories, setCategories] = useState<Category[]>([]);
  const [stores, setStores] = useState<Store[]>([]);

  // Dialogs
  const [archiveDialogOpen, setArchiveDialogOpen] = useState(false);
  const [selectedImageIndex, setSelectedImageIndex] = useState(0);

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

  // Fetch product data
  const fetchProduct = useCallback(async () => {
    if (!productId) return;

    setLoading(true);
    setError(null);
    try {
      // Get product data
      const productData = await productApi.getProduct(productId);
      // If it's a parent product with variants, fetch children separately
      if (productData.productType === 'parent') {
        const productWithChildren = await productApi.getProductChildren(productId);
        setProduct(productWithChildren);
      } else {
        setProduct(productData as ProductWithChildren);
      }
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
    if (open && productId) {
      fetchProduct();
      setSelectedImageIndex(0);
    } else {
      setProduct(null);
    }
  }, [open, productId, fetchProduct]);

  // Helper functions
  const getCategoryName = (categoryId?: string) => {
    if (!categoryId) return '-';
    return categories.find(c => c.id === categoryId)?.name || categoryId;
  };

  const getStoreName = (storeId?: string) => {
    if (!storeId) return '-';
    return stores.find(s => s.id === storeId)?.name || storeId;
  };

  const formatCurrency = (value?: number) => {
    if (value === undefined || value === null) return '-';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  // Actions
  const handleArchive = async () => {
    if (!product) return;

    setActionLoading(true);
    try {
      if (product.isArchived) {
        await productApi.unarchiveProduct(product.id);
      } else {
        await productApi.archiveProduct(product.id);
      }
      setArchiveDialogOpen(false);
      fetchProduct();
      onRefresh();
    } catch (err) {
      console.error('Failed to archive/unarchive product:', err);
      setError(
        product.isArchived
          ? (t('products.unarchiveError') || 'Failed to restore product')
          : (t('products.archiveError') || 'Failed to archive product')
      );
    } finally {
      setActionLoading(false);
    }
  };

  const handleSyncAggregates = async () => {
    if (!product) return;

    setActionLoading(true);
    try {
      await productApi.syncParentAggregates(product.id);
      fetchProduct();
      onRefresh();
    } catch (err) {
      console.error('Failed to sync aggregates:', err);
      setError(t('products.syncError') || 'Failed to sync aggregates');
    } finally {
      setActionLoading(false);
    }
  };

  const handleSetDefaultVariant = async (childId: string) => {
    setActionLoading(true);
    try {
      await productApi.setDefaultVariant(childId);
      fetchProduct();
      onRefresh();
    } catch (err) {
      console.error('Failed to set default variant:', err);
      setError(t('products.setDefaultError') || 'Failed to set default variant');
    } finally {
      setActionLoading(false);
    }
  };

  const isParentProduct = product?.productType === 'parent' || (product?.children && product.children.length > 0);

  return (
    <>
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
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography variant="h6">{product?.name || t('products.title')}</Typography>
            {product?.isArchived && (
              <Chip label={t('products.archived')} size="small" color="warning" />
            )}
          </Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            {product && (
              <>
                <Tooltip title={t('common.edit')}>
                  <IconButton onClick={() => onEdit(product.id)} size="small">
                    <EditIcon />
                  </IconButton>
                </Tooltip>
                <Tooltip title={product.isArchived ? t('products.restore') : t('products.archive')}>
                  <IconButton
                    onClick={() => setArchiveDialogOpen(true)}
                    size="small"
                    color={product.isArchived ? 'primary' : 'error'}
                  >
                    {product.isArchived ? <RestoreIcon /> : <DeleteIcon />}
                  </IconButton>
                </Tooltip>
              </>
            )}
            <IconButton onClick={onClose} size="small">
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>

        <DialogContent dividers>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : error ? (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          ) : product ? (
            <Grid container spacing={3}>
              {/* Product Images */}
              <Grid item xs={12} md={4}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      {t('products.detail.productImages')}
                    </Typography>
                    {product.imageUrls && product.imageUrls.length > 0 ? (
                      <>
                        <Box
                          component="img"
                          src={product.imageUrls[selectedImageIndex]}
                          alt={product.name}
                          sx={{
                            width: '100%',
                            aspectRatio: '1',
                            objectFit: 'cover',
                            borderRadius: 1,
                            mb: 1,
                          }}
                        />
                        {product.imageUrls.length > 1 && (
                          <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                            {product.imageUrls.map((url, idx) => (
                              <Box
                                key={idx}
                                component="img"
                                src={url}
                                alt={`${product.name} ${idx + 1}`}
                                onClick={() => setSelectedImageIndex(idx)}
                                sx={{
                                  width: 48,
                                  height: 48,
                                  objectFit: 'cover',
                                  borderRadius: 0.5,
                                  cursor: 'pointer',
                                  border: idx === selectedImageIndex ? '2px solid' : '2px solid transparent',
                                  borderColor: idx === selectedImageIndex ? 'primary.main' : 'transparent',
                                  opacity: idx === selectedImageIndex ? 1 : 0.7,
                                  '&:hover': { opacity: 1 },
                                }}
                              />
                            ))}
                          </Box>
                        )}
                      </>
                    ) : (
                      <Box
                        sx={{
                          width: '100%',
                          aspectRatio: '1',
                          bgcolor: 'grey.100',
                          borderRadius: 1,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        <Typography variant="body2" color="text.secondary">
                          {t('products.detail.noImagesAvailable')}
                        </Typography>
                      </Box>
                    )}
                  </CardContent>
                </Card>
              </Grid>

              {/* Product Information */}
              <Grid item xs={12} md={8}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      {t('products.detail.productInfo')}
                    </Typography>
                    
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        {product.isFeatured && (
                          <Tooltip title={t('products.featured')}>
                            <FeaturedIcon color="warning" />
                          </Tooltip>
                        )}
                        {product.isActive ? (
                          <Tooltip title={t('common.active')}>
                            <VisibilityIcon color="success" />
                          </Tooltip>
                        ) : (
                          <Tooltip title={t('common.inactive')}>
                            <HiddenIcon color="disabled" />
                          </Tooltip>
                        )}
                      </Box>
                      <Chip
                        label={product.isActive ? t('common.active') : t('common.inactive')}
                        size="small"
                        color={product.isActive ? 'success' : 'default'}
                      />
                      {product.sku && (
                        <Typography variant="body2" color="text.secondary">
                          SKU: {product.sku}
                        </Typography>
                      )}
                    </Box>

                    <Divider sx={{ my: 2 }} />

                    <Grid container spacing={2}>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">{t('products.currentPrice')}</Typography>
                        <Typography variant="h6">{formatCurrency(product.currentPrice)}</Typography>
                      </Grid>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">{t('products.originalPrice')}</Typography>
                        <Typography variant="h6" sx={{ textDecoration: product.originalPrice !== product.currentPrice ? 'line-through' : 'none', color: 'text.secondary' }}>
                          {formatCurrency(product.originalPrice)}
                        </Typography>
                      </Grid>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">{t('products.stock')}</Typography>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <InventoryIcon fontSize="small" color={product.stockLeft === 0 ? 'error' : product.stockLeft < 10 ? 'warning' : 'action'} />
                          <Typography variant="body1">{product.stockLeft} {product.unit}</Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">{t('products.minOrderQty')}</Typography>
                        <Typography variant="body1">{product.minimumOrderQuantity}</Typography>
                      </Grid>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">{t('products.category')}</Typography>
                        <Typography variant="body1">{getCategoryName(product.categoryId)}</Typography>
                      </Grid>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">{t('products.store')}</Typography>
                        <Typography variant="body1">{getStoreName(product.storeId)}</Typography>
                      </Grid>
                    </Grid>

                    <Divider sx={{ my: 2 }} />

                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      {t('products.detail.description')}
                    </Typography>
                    <Typography variant="body2">
                      {product.description || t('products.detail.noDescription')}
                    </Typography>

                    {/* Attributes */}
                    {product.attributes && product.attributes.length > 0 && (
                      <>
                        <Divider sx={{ my: 2 }} />
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          {t('products.detail.attributeLabel')}
                        </Typography>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                          {product.attributes.map((attr, idx) => (
                            <Chip
                              key={idx}
                              label={`${attr.attributeName}: ${attr.attributeValue}`}
                              size="small"
                              variant="outlined"
                            />
                          ))}
                        </Box>
                      </>
                    )}

                    <Divider sx={{ my: 2 }} />

                    <Grid container spacing={2}>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">{t('products.detail.createdAt')}</Typography>
                        <Typography variant="body2">{formatDate(product.createdAt)}</Typography>
                      </Grid>
                      <Grid item xs={6}>
                        <Typography variant="caption" color="text.secondary">{t('products.detail.updatedAt')}</Typography>
                        <Typography variant="body2">{formatDate(product.updatedAt)}</Typography>
                      </Grid>
                    </Grid>
                  </CardContent>
                </Card>
              </Grid>

              {/* Variants Section (for parent products) */}
              {isParentProduct && (
                <Grid item xs={12}>
                  <Card variant="outlined">
                    <CardContent>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                        <Box>
                          <Typography variant="subtitle1" fontWeight={600}>
                            {t('products.detail.variants')}
                          </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <Tooltip title={t('products.detail.syncAggregatesHelp')}>
                            <Button
                              size="small"
                              startIcon={<SyncIcon />}
                              onClick={handleSyncAggregates}
                              disabled={actionLoading}
                            >
                              {t('products.detail.syncAggregates')}
                            </Button>
                          </Tooltip>
                          <Button
                            size="small"
                            variant="contained"
                            startIcon={<AddIcon />}
                            onClick={() => onAddVariant(product.id)}
                          >
                            {t('products.detail.addVariant')}
                          </Button>
                        </Box>
                      </Box>

                      {product.children && product.children.length > 0 ? (
                        <TableContainer component={Paper} variant="outlined">
                          <Table size="small">
                            <TableHead>
                              <TableRow>
                                <TableCell>{t('products.productName')}</TableCell>
                                <TableCell>{t('products.sku')}</TableCell>
                                <TableCell align="right">{t('products.price')}</TableCell>
                                <TableCell align="right">{t('products.stock')}</TableCell>
                                <TableCell>{t('common.status')}</TableCell>
                                <TableCell align="center">{t('common.actions')}</TableCell>
                              </TableRow>
                            </TableHead>
                            <TableBody>
                              {product.children.map((child) => (
                                <TableRow
                                  key={child.id}
                                  sx={{
                                    bgcolor: child.isDefaultVariant ? 'action.selected' : 'transparent',
                                  }}
                                >
                                  <TableCell>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                      <Avatar
                                        variant="rounded"
                                        src={child.imageUrls?.[0]}
                                        sx={{ width: 32, height: 32 }}
                                      >
                                        {child.name.charAt(0)}
                                      </Avatar>
                                      <Box>
                                        <Typography variant="body2">{child.name}</Typography>
                                        {child.isDefaultVariant && (
                                          <Chip
                                            icon={<DefaultIcon />}
                                            label={t('products.detail.default')}
                                            size="small"
                                            color="primary"
                                          />
                                        )}
                                      </Box>
                                    </Box>
                                  </TableCell>
                                  <TableCell>{child.sku || '-'}</TableCell>
                                  <TableCell align="right">{formatCurrency(child.currentPrice)}</TableCell>
                                  <TableCell align="right">{child.stockLeft}</TableCell>
                                  <TableCell>
                                    <Chip
                                      label={child.isActive ? t('common.active') : t('common.inactive')}
                                      size="small"
                                      color={child.isActive ? 'success' : 'default'}
                                    />
                                  </TableCell>
                                  <TableCell align="center">
                                    <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                                      <Tooltip title={t('common.edit')}>
                                        <IconButton
                                          size="small"
                                          onClick={() => onEdit(child.id)}
                                        >
                                          <EditIcon fontSize="small" />
                                        </IconButton>
                                      </Tooltip>
                                      {!child.isDefaultVariant && (
                                        <Tooltip title={t('products.detail.setDefault')}>
                                          <IconButton
                                            size="small"
                                            onClick={() => handleSetDefaultVariant(child.id)}
                                            disabled={actionLoading}
                                          >
                                            <DefaultIcon fontSize="small" />
                                          </IconButton>
                                        </Tooltip>
                                      )}
                                    </Box>
                                  </TableCell>
                                </TableRow>
                              ))}
                            </TableBody>
                          </Table>
                        </TableContainer>
                      ) : (
                        <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center', py: 3 }}>
                          {t('products.detail.noVariants')}
                        </Typography>
                      )}
                    </CardContent>
                  </Card>
                </Grid>
              )}
            </Grid>
          ) : null}
        </DialogContent>

        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button onClick={onClose}>
            {t('common.close')}
          </Button>
          {product && (
            <Button
              variant="contained"
              onClick={() => onEdit(product.id)}
              startIcon={<EditIcon />}
            >
              {t('common.edit')}
            </Button>
          )}
        </DialogActions>
      </Dialog>

      {/* Archive Confirmation Dialog */}
      <ConfirmDialog
        open={archiveDialogOpen}
        title={product?.isArchived ? t('products.unarchiveTitle') : t('products.archiveTitle')}
        message={
          product?.isArchived
            ? t('products.unarchiveMessage', { name: product?.name })
            : t('products.archiveMessage', { name: product?.name })
        }
        confirmText={product?.isArchived ? t('products.restore') : t('products.archive')}
        confirmColor={product?.isArchived ? 'primary' : 'error'}
        onConfirm={handleArchive}
        onCancel={() => setArchiveDialogOpen(false)}
        loading={actionLoading}
      />
    </>
  );
};

export default ProductDetailModal;
