import React, { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Typography,
  IconButton,
  CircularProgress,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Chip,
  Grid,
  Divider,
  Avatar,
  alpha,
} from '@mui/material';
import {
  Close as CloseIcon,
  Edit as EditIcon,
  LocationOn as LocationIcon,
  Store as StoreIcon,
  Public as PublicIcon,
} from '@mui/icons-material';
import { storeApi, type Store } from '@/services/catalogApi';
import { storeTypeColors } from '@theme/colors';

// Store type configuration
type StoreType = 'ETWMega' | 'ETWMarket' | 'ETWtoGO' | 'ETWXpress' | 'unknown';

const storeTypeLabels: Record<StoreType, string> = {
  ETWMega: 'MEGA',
  ETWMarket: 'MARKET',
  ETWtoGO: 'toGO',
  ETWXpress: 'XPRESS',
  unknown: 'Unknown',
};

const storeTypeToColorKey: Record<StoreType, keyof typeof storeTypeColors> = {
  ETWMega: 'mega',
  ETWMarket: 'market',
  ETWtoGO: 'toGo',
  ETWXpress: 'xpress',
  unknown: 'mega',
};

const miniAppTypeLabels: Record<string, string> = {
  ETWtoB: 'ETW toB',
  ETWtoC: 'ETW toC',
  ETWtoU: 'ETW toU',
};

interface StoreDetailModalProps {
  open: boolean;
  storeId: string | null;
  onClose: () => void;
  onEdit: (storeId: string) => void;
}

const StoreDetailModal: React.FC<StoreDetailModalProps> = ({
  open,
  storeId,
  onClose,
  onEdit,
}) => {
  const { t } = useTranslation();

  const [store, setStore] = useState<Store | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchStore = useCallback(async () => {
    if (!storeId) return;

    setLoading(true);
    setError(null);
    try {
      const data = await storeApi.getStore(storeId);
      setStore(data);
    } catch (err) {
      console.error('Failed to fetch store:', err);
      setError(t('stores.fetchError') || 'Failed to load store details');
    } finally {
      setLoading(false);
    }
  }, [storeId, t]);

  useEffect(() => {
    if (open && storeId) {
      fetchStore();
    } else {
      setStore(null);
    }
  }, [open, storeId, fetchStore]);

  const getStoreTypeColor = (type: string) => {
    const colorKey = storeTypeToColorKey[type as StoreType] || 'mega';
    return storeTypeColors[colorKey];
  };

  const getStoreTypeLabel = (type: string) => {
    return storeTypeLabels[type as StoreType] || type || 'Unknown';
  };

  const getMiniAppTypeLabel = (type: string) => {
    return miniAppTypeLabels[type] || type || '-';
  };

  const handleEdit = () => {
    if (storeId) {
      onEdit(storeId);
    }
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { maxHeight: '90vh' },
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Typography variant="h6">
            {t('stores.storeDetails') || 'Store Details'}
          </Typography>
          <IconButton onClick={onClose}>
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
          <Alert severity="error">{error}</Alert>
        ) : store ? (
          <Box>
            {/* Header with Image and Basic Info */}
            <Box sx={{ display: 'flex', gap: 3, mb: 3 }}>
              <Avatar
                variant="rounded"
                src={store.imageUrl}
                sx={{
                  width: 120,
                  height: 120,
                  bgcolor: alpha(getStoreTypeColor(store.storeType), 0.1),
                }}
              >
                <StoreIcon sx={{ fontSize: 48, color: getStoreTypeColor(store.storeType) }} />
              </Avatar>
              <Box sx={{ flex: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
                  <Typography variant="h5" fontWeight={600}>
                    {store.name}
                  </Typography>
                  <Chip
                    label={store.isActive ? t('common.active') : t('common.inactive')}
                    size="small"
                    color={store.isActive ? 'success' : 'default'}
                  />
                </Box>
                <Box sx={{ display: 'flex', gap: 1, mb: 2 }}>
                  <Chip
                    label={getStoreTypeLabel(store.storeType)}
                    size="small"
                    sx={{
                      bgcolor: alpha(getStoreTypeColor(store.storeType), 0.1),
                      color: getStoreTypeColor(store.storeType),
                      fontWeight: 600,
                    }}
                  />
                  {store.etwMiniAppType && (
                    <Chip
                      label={getMiniAppTypeLabel(store.etwMiniAppType)}
                      size="small"
                      variant="outlined"
                    />
                  )}
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1, color: 'text.secondary' }}>
                  <LocationIcon fontSize="small" sx={{ mt: 0.25 }} />
                  <Typography variant="body2">
                    {store.address}
                  </Typography>
                </Box>
              </Box>
            </Box>

            <Divider sx={{ my: 3 }} />

            {/* Details Grid */}
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('stores.city') || 'City'}
                </Typography>
                <Typography variant="body1">{store.city}</Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('stores.storeType') || 'Store Type'}
                </Typography>
                <Typography variant="body1">{getStoreTypeLabel(store.storeType)}</Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('stores.miniAppType') || 'Mini App Type'}
                </Typography>
                <Typography variant="body1">{getMiniAppTypeLabel(store.etwMiniAppType || '')}</Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('common.status') || 'Status'}
                </Typography>
                <Chip
                  label={store.isActive ? t('common.active') : t('common.inactive')}
                  size="small"
                  color={store.isActive ? 'success' : 'default'}
                />
              </Grid>

              <Grid item xs={12}>
                <Divider sx={{ my: 1 }} />
              </Grid>

              <Grid item xs={12}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <PublicIcon fontSize="small" />
                    {t('stores.coordinates') || 'Coordinates'}
                  </Box>
                </Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('stores.latitude') || 'Latitude'}
                </Typography>
                <Typography variant="body1" fontFamily="monospace">
                  {store.latitude?.toFixed(8) || '-'}
                </Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('stores.longitude') || 'Longitude'}
                </Typography>
                <Typography variant="body1" fontFamily="monospace">
                  {store.longitude?.toFixed(8) || '-'}
                </Typography>
              </Grid>

              <Grid item xs={12}>
                <Divider sx={{ my: 1 }} />
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('common.createdAt') || 'Created At'}
                </Typography>
                <Typography variant="body2">
                  {new Date(store.createdAt).toLocaleString()}
                </Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('common.updatedAt') || 'Updated At'}
                </Typography>
                <Typography variant="body2">
                  {new Date(store.updatedAt).toLocaleString()}
                </Typography>
              </Grid>
            </Grid>
          </Box>
        ) : (
          <Alert severity="info">{t('stores.noStoreSelected') || 'No store selected'}</Alert>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose}>
          {t('common.close') || 'Close'}
        </Button>
        <Button
          variant="contained"
          onClick={handleEdit}
          startIcon={<EditIcon />}
          disabled={!store}
        >
          {t('common.edit') || 'Edit'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default StoreDetailModal;
