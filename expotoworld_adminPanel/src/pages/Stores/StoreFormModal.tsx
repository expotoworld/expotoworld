import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  TextField,
  Button,
  Grid,
  Typography,
  IconButton,
  CircularProgress,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Switch,
  FormControlLabel,
  Card,
  CardContent,
  Chip,
} from '@mui/material';
import {
  Save as SaveIcon,
  Close as CloseIcon,
  CloudUpload as CloudUploadIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { CustomDropdown } from '@components/common';
import { storeApi, regionApi, type Store, type Region } from '@/services/catalogApi';

// Store types configuration
const storeTypeOptions = [
  { value: 'ETWMega', label: 'MEGA' },
  { value: 'ETWMarket', label: 'MARKET' },
  { value: 'ETWtoGO', label: 'toGO' },
  { value: 'ETWXpress', label: 'XPRESS' },
];

const miniAppTypeOptions = [
  { value: 'ETWtoB', label: 'ETW toB' },
  { value: 'ETWtoC', label: 'ETW toC' },
  { value: 'ETWtoU', label: 'ETW toU' },
];

interface FormData {
  name: string;
  city: string;
  address: string;
  latitude: string;
  longitude: string;
  imageUrl: string;
  regionId: string;
  etwStoreType: string;
  etwMiniAppType: string;
  isActive: boolean;
  // Image upload state
  imageFile?: File;
  imagePreviewUrl?: string;
}

const initialFormData: FormData = {
  name: '',
  city: '',
  address: '',
  latitude: '',
  longitude: '',
  imageUrl: '',
  regionId: '',
  etwStoreType: '',
  etwMiniAppType: '',
  isActive: true,
  imageFile: undefined,
  imagePreviewUrl: undefined,
};

interface StoreFormModalProps {
  open: boolean;
  storeId?: string;
  onClose: () => void;
  onSuccess: () => void;
}

const StoreFormModal: React.FC<StoreFormModalProps> = ({
  open,
  storeId,
  onClose,
  onSuccess,
}) => {
  const { t } = useTranslation();
  const isEditMode = !!storeId;

  // Form state
  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Image upload state
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = useState(false);

  // Reference data
  const [regions, setRegions] = useState<Region[]>([]);

  // Fetch reference data
  const fetchReferenceData = useCallback(async () => {
    try {
      const regionsRes = await regionApi.getRegions();
      setRegions(regionsRes.items || []);
    } catch (err) {
      console.error('Failed to fetch regions:', err);
    }
  }, []);

  // Fetch store data in edit mode
  const fetchStore = useCallback(async () => {
    if (!storeId) return;

    setLoading(true);
    setError(null);
    try {
      const store = await storeApi.getStore(storeId);
      setFormData({
        name: store.name || '',
        city: store.city || '',
        address: store.address || '',
        latitude: store.latitude?.toString() || '',
        longitude: store.longitude?.toString() || '',
        imageUrl: store.imageUrl || '',
        regionId: store.regionId || '',
        etwStoreType: store.etwStoreType || '',
        etwMiniAppType: store.etwMiniAppType || '',
        isActive: store.isActive ?? true,
      });
    } catch (err) {
      console.error('Failed to fetch store:', err);
      setError(t('stores.fetchError') || 'Failed to load store');
    } finally {
      setLoading(false);
    }
  }, [storeId, t]);

  // Load data when modal opens
  useEffect(() => {
    if (open) {
      fetchReferenceData();
      if (isEditMode) {
        fetchStore();
      } else {
        setFormData(initialFormData);
      }
    }
  }, [open, isEditMode, fetchReferenceData, fetchStore]);

  const handleChange = (field: keyof FormData) => (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    setFormData((prev) => ({
      ...prev,
      [field]: event.target.value,
    }));
  };

  const handleSwitchChange = (field: keyof FormData) => (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    setFormData((prev) => ({
      ...prev,
      [field]: event.target.checked,
    }));
  };

  const handleDropdownChange = (field: keyof FormData) => (value: string) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  // Image file handling
  const handleFileSelect = (files: FileList | null) => {
    if (!files || files.length === 0) return;

    const file = files[0];
    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    const maxSize = 10 * 1024 * 1024; // 10MB

    if (!validTypes.includes(file.type)) {
      setError(t('stores.invalidImageType') || 'Invalid image type. Please use JPEG, PNG, GIF, or WebP.');
      return;
    }

    if (file.size > maxSize) {
      setError(t('stores.imageTooLarge') || 'Image is too large. Maximum size is 10MB.');
      return;
    }

    // Revoke previous preview URL
    if (formData.imagePreviewUrl) {
      URL.revokeObjectURL(formData.imagePreviewUrl);
    }

    const previewUrl = URL.createObjectURL(file);
    setFormData((prev) => ({
      ...prev,
      imageFile: file,
      imagePreviewUrl: previewUrl,
      imageUrl: '', // Clear URL since we have a file now
    }));
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

  const removeImage = () => {
    if (formData.imagePreviewUrl) {
      URL.revokeObjectURL(formData.imagePreviewUrl);
    }
    setFormData((prev) => ({
      ...prev,
      imageFile: undefined,
      imagePreviewUrl: undefined,
      imageUrl: '',
    }));
  };

  // Clean up preview URL on unmount
  useEffect(() => {
    return () => {
      if (formData.imagePreviewUrl) {
        URL.revokeObjectURL(formData.imagePreviewUrl);
      }
    };
  }, []);

  const handleSubmit = async () => {
    // Validate required fields
    if (!formData.name.trim()) {
      setError(t('stores.nameRequired') || 'Store name is required');
      return;
    }
    if (!formData.city.trim()) {
      setError(t('stores.cityRequired') || 'City is required');
      return;
    }
    if (!formData.address.trim()) {
      setError(t('stores.addressRequired') || 'Address is required');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      let finalImageUrl = formData.imageUrl;
      let savedStoreId = storeId;

      // For new stores, we need to create the store first to get an ID for the image path
      // For existing stores, we can upload right away
      if (!isEditMode) {
        // Create store first without image
        const storeData: Partial<Store> = {
          name: formData.name.trim(),
          city: formData.city.trim(),
          address: formData.address.trim(),
          latitude: formData.latitude ? parseFloat(formData.latitude) : 0,
          longitude: formData.longitude ? parseFloat(formData.longitude) : 0,
          regionId: formData.regionId || undefined,
          etwStoreType: formData.etwStoreType || undefined,
          etwMiniAppType: formData.etwMiniAppType || undefined,
          isActive: formData.isActive,
        };
        const createdStore = await storeApi.createStore(storeData);
        savedStoreId = createdStore.id;
      }

      // If there's a file to upload, upload it now
      if (formData.imageFile && savedStoreId) {
        try {
          finalImageUrl = await storeApi.uploadStoreImage(
            savedStoreId,
            formData.imageFile
          );
        } catch (uploadErr) {
          console.error('Failed to upload image:', uploadErr);
          setError(t('stores.imageUploadError') || 'Failed to upload image');
          setSaving(false);
          return;
        }
      }

      // Update store with final data (including image URL if uploaded)
      if (savedStoreId) {
        const storeData: Partial<Store> = {
          name: formData.name.trim(),
          city: formData.city.trim(),
          address: formData.address.trim(),
          latitude: formData.latitude ? parseFloat(formData.latitude) : 0,
          longitude: formData.longitude ? parseFloat(formData.longitude) : 0,
          imageUrl: finalImageUrl || undefined,
          regionId: formData.regionId || undefined,
          etwStoreType: formData.etwStoreType || undefined,
          etwMiniAppType: formData.etwMiniAppType || undefined,
          isActive: formData.isActive,
        };
        await storeApi.updateStore(savedStoreId, storeData);
      }

      onSuccess();
      onClose();
    } catch (err) {
      console.error('Failed to save store:', err);
      setError(t('stores.saveError') || 'Failed to save store');
    } finally {
      setSaving(false);
    }
  };

  const handleClose = () => {
    if (!saving) {
      // Clean up preview URL
      if (formData.imagePreviewUrl) {
        URL.revokeObjectURL(formData.imagePreviewUrl);
      }
      setFormData(initialFormData);
      setError(null);
      onClose();
    }
  };

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: { maxHeight: '90vh' },
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Typography variant="h6">
            {isEditMode ? t('stores.editStore') || 'Edit Store' : t('stores.createStore') || 'Create Store'}
          </Typography>
          <IconButton onClick={handleClose} disabled={saving}>
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>

      <DialogContent dividers>
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress />
          </Box>
        ) : (
          <Box sx={{ pt: 1 }}>
            {error && (
              <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
                {error}
              </Alert>
            )}

            <Grid container spacing={3}>
              {/* Basic Information */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {t('stores.basicInfo') || 'Basic Information'}
                </Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label={t('stores.storeName') || 'Store Name'}
                  value={formData.name}
                  onChange={handleChange('name')}
                  required
                  size="small"
                />
              </Grid>

              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label={t('stores.city') || 'City'}
                  value={formData.city}
                  onChange={handleChange('city')}
                  required
                  size="small"
                />
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label={t('stores.address') || 'Address'}
                  value={formData.address}
                  onChange={handleChange('address')}
                  required
                  size="small"
                  multiline
                  rows={2}
                />
              </Grid>

              {/* Location */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom sx={{ mt: 2 }}>
                  {t('stores.location') || 'Location'}
                </Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label={t('stores.latitude') || 'Latitude'}
                  value={formData.latitude}
                  onChange={handleChange('latitude')}
                  size="small"
                  type="number"
                  inputProps={{ step: 'any' }}
                />
              </Grid>

              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label={t('stores.longitude') || 'Longitude'}
                  value={formData.longitude}
                  onChange={handleChange('longitude')}
                  size="small"
                  type="number"
                  inputProps={{ step: 'any' }}
                />
              </Grid>

              {/* Store Configuration */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom sx={{ mt: 2 }}>
                  {t('stores.configuration') || 'Configuration'}
                </Typography>
              </Grid>

              <Grid item xs={12} md={6}>
                <CustomDropdown
                  label={t('stores.storeType') || 'Store Type'}
                  value={formData.etwStoreType}
                  options={[
                    { value: '', label: t('common.selectOption') || 'Select...' },
                    ...storeTypeOptions,
                  ]}
                  onChange={handleDropdownChange('etwStoreType')}
                  fullWidth
                />
              </Grid>

              <Grid item xs={12} md={6}>
                <CustomDropdown
                  label={t('stores.miniAppType') || 'Mini App Type'}
                  value={formData.etwMiniAppType}
                  options={[
                    { value: '', label: t('common.selectOption') || 'Select...' },
                    ...miniAppTypeOptions,
                  ]}
                  onChange={handleDropdownChange('etwMiniAppType')}
                  fullWidth
                />
              </Grid>

              <Grid item xs={12} md={6}>
                <CustomDropdown
                  label={t('stores.region') || 'Region'}
                  value={formData.regionId}
                  options={[
                    { value: '', label: t('common.selectOption') || 'Select...' },
                    ...regions.map((r) => ({ value: r.id, label: r.name })),
                  ]}
                  onChange={handleDropdownChange('regionId')}
                  fullWidth
                />
              </Grid>

              <Grid item xs={12} md={6}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.isActive}
                      onChange={handleSwitchChange('isActive')}
                    />
                  }
                  label={t('common.active') || 'Active'}
                />
              </Grid>

              {/* Store Image Upload */}
              <Grid item xs={12}>
                <Card variant="outlined" sx={{ mt: 2 }}>
                  <CardContent>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      {t('stores.image') || 'Store Image'}
                    </Typography>

                    {/* Hidden file input */}
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept="image/jpeg,image/png,image/gif,image/webp"
                      style={{ display: 'none' }}
                      onChange={(e) => handleFileSelect(e.target.files)}
                    />

                    {/* Show existing/preview image or drag-drop area */}
                    {(formData.imageUrl || formData.imagePreviewUrl) ? (
                      <Box
                        sx={{
                          position: 'relative',
                          width: '100%',
                          maxWidth: 300,
                          mx: 'auto',
                        }}
                      >
                        <Box
                          sx={{
                            width: '100%',
                            paddingBottom: '100%', // Square aspect ratio
                            position: 'relative',
                            border: 1,
                            borderColor: 'divider',
                            borderRadius: 2,
                            overflow: 'hidden',
                            bgcolor: 'grey.100',
                          }}
                        >
                          <Box
                            component="img"
                            src={formData.imagePreviewUrl || formData.imageUrl}
                            alt="Store"
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
                          {/* Delete button */}
                          <IconButton
                            size="small"
                            onClick={removeImage}
                            sx={{
                              position: 'absolute',
                              top: 8,
                              right: 8,
                              bgcolor: 'rgba(0, 0, 0, 0.5)',
                              color: 'white',
                              '&:hover': {
                                bgcolor: 'error.main',
                              },
                            }}
                          >
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                          {/* Pending badge for local files */}
                          {formData.imageFile && !formData.imageUrl && (
                            <Chip
                              label={t('products.form.pending') || 'Pending'}
                              size="small"
                              color="warning"
                              sx={{
                                position: 'absolute',
                                bottom: 8,
                                left: 8,
                                fontSize: '0.7rem',
                              }}
                            />
                          )}
                        </Box>
                        {/* Change image button */}
                        <Button
                          size="small"
                          variant="outlined"
                          onClick={() => fileInputRef.current?.click()}
                          sx={{ mt: 1, width: '100%' }}
                        >
                          {t('stores.changeImage') || 'Change Image'}
                        </Button>
                      </Box>
                    ) : (
                      /* Drag & Drop Upload Area */
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
                          {t('stores.dragDropImage') || 'Drag & drop an image here, or click to select'}
                        </Typography>
                        <Typography variant="body2" color="text.disabled" sx={{ mt: 0.5 }}>
                          {t('stores.supportedFormats') || 'JPEG, PNG, GIF, WebP (max 10MB)'}
                        </Typography>
                      </Box>
                    )}
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={handleClose} disabled={saving}>
          {t('common.cancel') || 'Cancel'}
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={loading || saving}
          startIcon={saving ? <CircularProgress size={20} /> : <SaveIcon />}
        >
          {saving ? (t('common.saving') || 'Saving...') : (t('common.save') || 'Save')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default StoreFormModal;
