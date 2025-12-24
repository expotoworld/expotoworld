import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Tabs,
  Tab,
  TextField,
  InputAdornment,
  Button,
  Typography,
  IconButton,
  Tooltip,
  Switch,
  FormControlLabel,
  Grid,
  Chip,
  CardMedia,
  CardActions,
} from '@mui/material';
import {
  Search as SearchIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  VisibilityOff as HideIcon,
  Image as ImageIcon,
  Star as StarIcon,
} from '@mui/icons-material';
import { ConfirmDialog } from '@components/common';
import type { Banner, FeaturedProduct } from '@/types';

// TODO: NEED TO FULLY IMPLEMENT - This is a placeholder page

// TODO: DUMMY DATA - Replace with actual API calls
const mockBanners: Banner[] = [
  {
    id: 'banner-1',
    title: 'Summer Sale 2024',
    subtitle: 'Up to 50% off on selected items',
    imageUrl: 'https://picsum.photos/seed/banner1/800/300',
    linkUrl: '/promotions/summer-sale',
    isActive: true,
    startDate: '2024-06-01T00:00:00Z',
    endDate: '2024-08-31T23:59:59Z',
    position: 1,
    createdAt: '2024-05-15T10:00:00Z',
    updatedAt: '2024-05-20T14:30:00Z',
  },
  {
    id: 'banner-2',
    title: 'New Arrivals',
    subtitle: 'Check out our latest products',
    imageUrl: 'https://picsum.photos/seed/banner2/800/300',
    linkUrl: '/products?filter=new',
    isActive: true,
    startDate: '2024-01-01T00:00:00Z',
    endDate: '2024-12-31T23:59:59Z',
    position: 2,
    createdAt: '2024-01-01T10:00:00Z',
    updatedAt: '2024-01-10T08:00:00Z',
  },
  {
    id: 'banner-3',
    title: 'Free Shipping',
    subtitle: 'On orders over $50',
    imageUrl: 'https://picsum.photos/seed/banner3/800/300',
    linkUrl: '/shipping-info',
    isActive: false,
    startDate: '2024-01-01T00:00:00Z',
    endDate: '2024-12-31T23:59:59Z',
    position: 3,
    createdAt: '2024-01-01T10:00:00Z',
    updatedAt: '2024-03-15T12:00:00Z',
  },
];

const mockFeaturedProducts: FeaturedProduct[] = [
  {
    id: 'featured-1',
    productId: 'product-1',
    productName: 'Wireless Headphones',
    productImage: 'https://picsum.photos/seed/prod1/200/200',
    productPrice: 99.99,
    displayOrder: 1,
    isActive: true,
    scope: 'global',
    createdAt: '2024-01-10T10:00:00Z',
    updatedAt: '2024-01-15T14:30:00Z',
  },
  {
    id: 'featured-2',
    productId: 'product-3',
    productName: 'Smart Watch Pro',
    productImage: 'https://picsum.photos/seed/prod3/200/200',
    productPrice: 249.99,
    displayOrder: 2,
    isActive: true,
    scope: 'global',
    createdAt: '2024-01-12T09:00:00Z',
    updatedAt: '2024-01-14T11:00:00Z',
  },
  {
    id: 'featured-3',
    productId: 'product-5',
    productName: 'Bluetooth Speaker',
    productImage: 'https://picsum.photos/seed/prod5/200/200',
    productPrice: 49.99,
    displayOrder: 3,
    isActive: true,
    scope: 'store',
    storeId: 'store-1',
    storeName: 'MEGA Store Downtown',
    createdAt: '2024-01-08T14:00:00Z',
    updatedAt: '2024-01-09T10:00:00Z',
  },
  {
    id: 'featured-4',
    productId: 'product-2',
    productName: 'Organic Coffee',
    productImage: 'https://picsum.photos/seed/prod2/200/200',
    productPrice: 30.0,
    displayOrder: 4,
    isActive: false,
    scope: 'global',
    createdAt: '2024-01-05T11:00:00Z',
    updatedAt: '2024-01-06T09:30:00Z',
  },
];

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index }) => {
  return (
    <Box role="tabpanel" hidden={value !== index} sx={{ pt: 3 }}>
      {value === index && children}
    </Box>
  );
};

const ContentPage: React.FC = () => {
  const { t } = useTranslation();
  const [tabValue, setTabValue] = React.useState(0);
  const [bannerSearch, setBannerSearch] = React.useState('');
  const [productSearch, setProductSearch] = React.useState('');
  const [deleteDialog, setDeleteDialog] = React.useState<{
    open: boolean;
    type: 'banner' | 'featured';
    id: string | null;
    title: string;
  }>({
    open: false,
    type: 'banner',
    id: null,
    title: '',
  });

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const filteredBanners = mockBanners.filter((banner) =>
    banner.title.toLowerCase().includes(bannerSearch.toLowerCase())
  );

  const filteredFeaturedProducts = mockFeaturedProducts.filter((product) =>
    product.productName.toLowerCase().includes(productSearch.toLowerCase())
  );

  const handleDelete = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call API to delete
    // TODO: Implement delete API call for ${deleteDialog.type}: ${deleteDialog.id}
    setDeleteDialog({ open: false, type: 'banner', id: null, title: '' });
  };

  return (
    <Box>
      <Card elevation={0}>
        <CardContent sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)}>
            <Tab
              icon={<ImageIcon />}
              iconPosition="start"
              label={t('content.banners')}
            />
            <Tab
              icon={<StarIcon />}
              iconPosition="start"
              label={t('content.featuredProducts')}
            />
          </Tabs>
        </CardContent>

        {/* Banners Tab */}
        <TabPanel value={tabValue} index={0}>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
              <TextField
                placeholder={t('content.searchBanners')}
                value={bannerSearch}
                onChange={(e) => setBannerSearch(e.target.value)}
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
              <Button variant="contained" startIcon={<AddIcon />}>
                {t('content.addBanner')}
              </Button>
            </Box>

            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              {t('content.bannersGlobalOnly')}
            </Typography>

            <Grid container spacing={3}>
              {filteredBanners.map((banner) => (
                <Grid item xs={12} md={6} key={banner.id}>
                  <Card
                    elevation={0}
                    sx={{
                      border: 1,
                      borderColor: 'divider',
                      opacity: banner.isActive ? 1 : 0.6,
                    }}
                  >
                    <CardMedia
                      component="img"
                      height={150}
                      image={banner.imageUrl}
                      alt={banner.title}
                      sx={{ objectFit: 'cover' }}
                    />
                    <CardContent>
                      <Box
                        sx={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'flex-start',
                        }}
                      >
                        <Box>
                          <Typography variant="h6" gutterBottom>
                            {banner.title}
                          </Typography>
                          <Typography
                            variant="body2"
                            color="text.secondary"
                            gutterBottom
                          >
                            {banner.subtitle}
                          </Typography>
                        </Box>
                        <Chip
                          label={banner.isActive ? t('common.active') : t('common.inactive')}
                          color={banner.isActive ? 'success' : 'default'}
                          size="small"
                        />
                      </Box>
                      {banner.startDate && banner.endDate && (
                        <Typography variant="caption" color="text.secondary">
                          {formatDate(banner.startDate)} - {formatDate(banner.endDate)}
                        </Typography>
                      )}
                    </CardContent>
                    <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                      <FormControlLabel
                        control={
                          <Switch
                            checked={banner.isActive}
                            size="small"
                            // TODO: NEED TO FULLY IMPLEMENT - Toggle banner status
                          />
                        }
                        label={t('common.active')}
                      />
                      <Box>
                        <Tooltip title={t('common.edit')}>
                          <IconButton size="small">
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title={t('common.delete')}>
                          <IconButton
                            size="small"
                            color="error"
                            onClick={() =>
                              setDeleteDialog({
                                open: true,
                                type: 'banner',
                                id: banner.id,
                                title: banner.title,
                              })
                            }
                          >
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </CardActions>
                  </Card>
                </Grid>
              ))}
            </Grid>

            {filteredBanners.length === 0 && (
              <Box sx={{ textAlign: 'center', py: 6 }}>
                <ImageIcon sx={{ fontSize: 64, color: 'text.disabled', mb: 2 }} />
                <Typography color="text.secondary">
                  {t('content.noBanners')}
                </Typography>
              </Box>
            )}
          </CardContent>
        </TabPanel>

        {/* Featured Products Tab */}
        <TabPanel value={tabValue} index={1}>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
              <TextField
                placeholder={t('content.searchFeaturedProducts')}
                value={productSearch}
                onChange={(e) => setProductSearch(e.target.value)}
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
              <Button variant="contained" startIcon={<AddIcon />}>
                {t('content.addFeaturedProduct')}
              </Button>
            </Box>

            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              {t('content.featuredProductsEverywhere')}
            </Typography>

            <Grid container spacing={3}>
              {filteredFeaturedProducts.map((product) => (
                <Grid item xs={12} sm={6} md={4} lg={3} key={product.id}>
                  <Card
                    elevation={0}
                    sx={{
                      border: 1,
                      borderColor: 'divider',
                      opacity: product.isActive ? 1 : 0.6,
                    }}
                  >
                    <CardMedia
                      component="img"
                      height={160}
                      image={product.productImage}
                      alt={product.productName}
                      sx={{ objectFit: 'cover' }}
                    />
                    <CardContent sx={{ pb: 1 }}>
                      <Typography variant="subtitle1" fontWeight={600} noWrap>
                        {product.productName}
                      </Typography>
                      <Typography variant="h6" color="primary.main" gutterBottom>
                        {formatCurrency(product.productPrice)}
                      </Typography>
                      <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                        <Chip
                          label={product.isActive ? t('common.active') : t('common.inactive')}
                          color={product.isActive ? 'success' : 'default'}
                          size="small"
                        />
                        <Chip
                          label={product.scope === 'global' ? t('content.global') : product.storeName}
                          color={product.scope === 'global' ? 'primary' : 'secondary'}
                          size="small"
                          variant="outlined"
                        />
                      </Box>
                    </CardContent>
                    <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                      <Typography variant="caption" color="text.secondary">
                        #{product.displayOrder}
                      </Typography>
                      <Box>
                        <Tooltip title={product.isActive ? t('common.hide') : t('common.show')}>
                          <IconButton size="small">
                            {product.isActive ? (
                              <HideIcon fontSize="small" />
                            ) : (
                              <ViewIcon fontSize="small" />
                            )}
                          </IconButton>
                        </Tooltip>
                        <Tooltip title={t('common.edit')}>
                          <IconButton size="small">
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title={t('common.delete')}>
                          <IconButton
                            size="small"
                            color="error"
                            onClick={() =>
                              setDeleteDialog({
                                open: true,
                                type: 'featured',
                                id: product.id,
                                title: product.productName,
                              })
                            }
                          >
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </CardActions>
                  </Card>
                </Grid>
              ))}
            </Grid>

            {filteredFeaturedProducts.length === 0 && (
              <Box sx={{ textAlign: 'center', py: 6 }}>
                <StarIcon sx={{ fontSize: 64, color: 'text.disabled', mb: 2 }} />
                <Typography color="text.secondary">
                  {t('content.noFeaturedProducts')}
                </Typography>
              </Box>
            )}
          </CardContent>
        </TabPanel>
      </Card>

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialog.open}
        title={t('content.deleteConfirmTitle')}
        message={t('content.deleteConfirmMessage', { name: deleteDialog.title })}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDelete}
        onCancel={() => setDeleteDialog({ open: false, type: 'banner', id: null, title: '' })}
      />
    </Box>
  );
};

export default ContentPage;
