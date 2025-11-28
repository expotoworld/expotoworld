import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Grid,
  Card,
  CardMedia,
  Chip,
  Divider,
  IconButton,
} from '@mui/material';
import {
  Close as CloseIcon,
  Inventory as InventoryIcon,
  AttachMoney as PriceIcon,
  Category as CategoryIcon,
} from '@mui/icons-material';

import type { Product } from '../types/domain';

interface ProductDetailsModalProps {
  open: boolean;
  onClose: () => void;
  product: Product | null;
  onUpdated?: (product?: Product) => void;
}

import ImagePreviewModal from './ImagePreviewModal';

const ProductDetailsModal: React.FC<ProductDetailsModalProps> = ({ open, onClose, product, onUpdated }) => {
  const formatPrice = (price: number): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(price);
  };

  // Helper function to get the correct type display for a product (ETW naming)
  const getProductTypeDisplay = (product: Product): string | null | undefined => {
    // Prefer etw_mini_app_type field
    const miniAppType = product.etw_mini_app_type || product.mini_app_type;

    if (miniAppType === 'ETWtoB') {
      return 'ETW to B';
    } else if (miniAppType === 'ETWtoG') {
      return 'ETW to G';
    } else if (miniAppType === 'ETWtoU') {
      // For ETW to U, show store type
      return product.etw_store_type || 'ETW to U';
    } else if (miniAppType === 'ETWtoC') {
      // For ETW to C, show store type
      return product.etw_store_type || 'ETW to C';
    }
    // Fallback to ETW store type
    return product.etw_store_type;
  };

  const getStoreTypeChip = (product: Product): JSX.Element => {
    const typeDisplay = getProductTypeDisplay(product);

    // Color mapping for store/mini-app types (ETW primary, legacy fallback)
    const getTypeColor = (type: string | null | undefined): { bg: string; hover: string } => {
      const colorMap: Record<string, { bg: string; hover: string }> = {
        // ETW Mini-App Types
        'ETW to B': { bg: '#520ee6', hover: '#4a0dd1' }, // purple
        'ETW to U': { bg: '#2196f3', hover: '#1976d2' }, // blue
        'ETW to C': { bg: '#ffd556', hover: '#ffcc33' }, // yellow
        'ETW to G': { bg: '#076200', hover: '#054d00' }, // dark green
        // ETW Store Types
        'ETWMega': { bg: '#9c27b0', hover: '#7b1fa2' }, // purple
        'ETWMarket': { bg: '#673ab7', hover: '#512da8' }, // deep purple
        'ETWtoGO': { bg: '#3f51b5', hover: '#303f9f' }, // indigo
        'ETWXpress': { bg: '#2196f3', hover: '#1976d2' }, // blue
        // Legacy store types (for backward compatibility)
        零售商店: { bg: '#520ee6', hover: '#4a0dd1' }, // purple
        无人门店: { bg: '#2196f3', hover: '#1976d2' }, // blue
        无人仓店: { bg: '#4caf50', hover: '#388e3c' }, // green
        展销商店: { bg: '#ffd556', hover: '#ffcc33' }, // yellow
        展销商城: { bg: '#f38900', hover: '#e67c00' }, // orange
        团购团批: { bg: '#076200', hover: '#054d00' }, // dark green
      };
      return colorMap[type ?? ''] || { bg: '#757575', hover: '#616161' }; // default gray
    };

    const colors = getTypeColor(typeDisplay);

    return (
      <Chip
        label={typeDisplay}
        size="medium"
        variant="filled"
        sx={{
          fontWeight: 500,
          backgroundColor: colors.bg,
          color: '#fff',
          '&:hover': {
            backgroundColor: colors.hover,
          }
        }}
      />
    );
  };

  const getStatusChip = (isActive: boolean): JSX.Element => (
    <Chip
      label={isActive ? 'Active' : 'Inactive'}
      size="medium"
      color={isActive ? 'success' : 'default'}
      variant="filled"
      sx={{ fontWeight: 500 }}
    />
  );



  const [previewOpen, setPreviewOpen] = useState(false);

  if (!product) return null;

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { borderRadius: '12px' }
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            Product Details
          </Typography>
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>

      <DialogContent sx={{ pt: 6, pb: 2 }}>
        <Grid container spacing={3}>
          {/* Product Image */}
          <Grid item xs={12} md={4}>
            <Card sx={{ borderRadius: '12px' }}>
              <CardMedia
                component="img"
                height="300"
                image={product.image_urls?.[0] || '/placeholder-product.png'}
                alt={product.title}
                sx={{
                  objectFit: 'cover',
                  backgroundColor: '#f5f5f5',
                  cursor: 'pointer'
                }}
                onClick={() => setPreviewOpen(true)}
              />
            </Card>
          </Grid>

          {/* Product Information */}
          <Grid item xs={12} md={8}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {/* Title and SKU */}
              <Box>
                <Typography variant="h4" gutterBottom sx={{ fontWeight: 700 }}>
                  {product.title}
                </Typography>
                <Typography variant="body1" color="text.secondary" sx={{ fontFamily: 'monospace' }}>
                  SKU: {product.sku}
                </Typography>
              </Box>

              {/* Status Chips */}
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                {getStoreTypeChip(product)}
                {getStatusChip(Boolean(product.is_active))}
                {/* Featured tag - Only for ETWtoU and ETWtoC mini-apps */}
                {['ETWtoU', 'ETWtoC'].includes(product.etw_mini_app_type || product.mini_app_type || '') && product.is_featured && (
                  <Chip
                    label="热门推荐"
                    size="medium"
                    variant="filled"
                    sx={{
                      fontWeight: 500,
                      backgroundColor: '#e2430f',
                      color: '#fff',
                      '&:hover': {
                        backgroundColor: '#cc3a0e',
                      }
                    }}
                  />
                )}
                {/* Mini-APP 推荐 tag - For all mini-app types */}
                {product.is_mini_app_recommendation && (
                  <Chip
                    label="Mini-APP 推荐"
                    size="medium"
                    variant="filled"
                    sx={{
                      fontWeight: 500,
                      backgroundColor: '#0adcd5',
                      color: '#fff',
                      '&:hover': {
                        backgroundColor: '#09c4be',
                      }
                    }}
                  />
                )}
              </Box>

              {/* Pricing */}
              <Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                  <PriceIcon color="primary" />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    Pricing
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Typography variant="h5" sx={{ fontWeight: 700, color: 'primary.main' }}>
                    {formatPrice(product.main_price)}
                  </Typography>
                  {product.strikethrough_price && (
                    <Typography
                      variant="h6"
                      sx={{
                        textDecoration: 'line-through',
                        color: 'text.secondary',
                      }}
                    >
                      {formatPrice(product.strikethrough_price)}
                    </Typography>
                  )}
                </Box>
              </Box>

              {/* Stock Information */}
              {getProductTypeDisplay(product)?.includes('无人') && (
                <Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <InventoryIcon color="primary" />
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      Stock Information
                    </Typography>
                  </Box>
                  <Typography variant="body1">
                    {product.stock_left || 0} units available
                  </Typography>
                </Box>
              )}

              {/* Categories */}
              <Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                  <CategoryIcon color="primary" />
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>
                    Categories
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                  {product.category_ids && product.category_ids.length > 0 ? (
                    product.category_ids.map((categoryId) => (
                      <Chip
                        key={categoryId}
                        label={`Category ${categoryId}`}
                        size="medium"
                        variant="outlined"
                        color="primary"
                      />
                    ))
                  ) : (
                    <Typography variant="body2" color="text.secondary">
                      No categories assigned
                    </Typography>
                  )}
                </Box>
              </Box>

              {/* Featured Status - Only for Unmanned Stores */}
              {product.store_type?.toLowerCase() === 'unmanned' && (
                <Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      Featured Status
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    {product.is_featured ? (
                      <Chip
                        label="热门推荐 - Featured Product"
                        size="medium"
                        color="secondary"
                        variant="filled"
                        sx={{ fontWeight: 500 }}
                      />
                    ) : (
                      <Chip
                        label="Not Featured"
                        size="medium"
                        variant="outlined"
                        sx={{ fontWeight: 500 }}
                      />
                    )}
                  </Box>
                  <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                    {product.is_featured
                      ? 'This product appears in the main app\'s featured section'
                      : 'This product is not featured in the main app'
                    }
                  </Typography>
                </Box>
              )}
            </Box>
          </Grid>

          {/* Descriptions */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />

            {/* Short Description */}
            {product.description_short && (
              <Box sx={{ mb: 3 }}>
                <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                  Short Description
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  {product.description_short}
                </Typography>
              </Box>
            )}

            {/* Long Description */}
            {product.description_long && (
              <Box>
                <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
                  Detailed Description
                </Typography>
                <Typography variant="body1" color="text.secondary" sx={{ lineHeight: 1.6 }}>
                  {product.description_long}
                </Typography>
              </Box>
            )}
          </Grid>

          {/* Metadata */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Box sx={{ display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Created At
                </Typography>
                <Typography variant="body2">
                  {product.created_at ? new Date(product.created_at).toLocaleDateString() : 'N/A'}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Last Updated
                </Typography>
                <Typography variant="body2">
                  {product.updated_at ? new Date(product.updated_at).toLocaleDateString() : 'N/A'}
                </Typography>
              </Box>
            </Box>
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ p: 3, pt: 1 }}>
        <Button onClick={onClose} variant="outlined">
          Close
        </Button>
      </DialogActions>
      {/* Image Preview / Manage Modal */}
      <ImagePreviewModal
        open={previewOpen}
        onClose={() => setPreviewOpen(false)}
        mode="product"
        entity={{ id: product.id }}
        onUpdated={onUpdated}
      />
    </Dialog>
  );
};

export default ProductDetailsModal;
