import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  TextField,
  Button,
  Typography,
  IconButton,
  CircularProgress,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControlLabel,
  Switch,
  LinearProgress,
} from '@mui/material';
import {
  Save as SaveIcon,
  Close as CloseIcon,
  CloudUpload as CloudUploadIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { categoryApi } from '@/services/catalogApi';

interface ImageState {
  url: string;
  file?: File;
  previewUrl?: string;
  uploading: boolean;
  uploadProgress: number;
}

interface FormData {
  name: string;
  displayOrder: number;
  isActive: boolean;
}

const initialFormData: FormData = {
  name: '',
  displayOrder: 0,
  isActive: true,
};

const initialImageState: ImageState = {
  url: '',
  uploading: false,
  uploadProgress: 0,
};

interface SubcollectionFormModalProps {
  open: boolean;
  collectionId: string;
  collectionName?: string;
  subcollectionId?: string;
  onClose: () => void;
  onSuccess: () => void;
}

const SubcollectionFormModal: React.FC<SubcollectionFormModalProps> = ({
  open,
  collectionId,
  collectionName,
  subcollectionId,
  onClose,
  onSuccess,
}) => {
  const { t } = useTranslation();
  const isEditMode = !!subcollectionId;
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [imageState, setImageState] = useState<ImageState>(initialImageState);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [dragOver, setDragOver] = useState(false);

  const fetchSubcollection = useCallback(async () => {
    if (!subcollectionId) return;

    setLoading(true);
    setError(null);
    try {
      const subcollections = await categoryApi.getSubcollections(collectionId);
      const subcollection = subcollections.find(sc => sc.id === subcollectionId);

      if (subcollection) {
        setFormData({
          name: subcollection.name || '',
          displayOrder: subcollection.displayOrder ?? 0,
          isActive: subcollection.isActive ?? true,
        });
        setImageState({
          url: subcollection.imageUrl || '',
          uploading: false,
          uploadProgress: 0,
        });
      } else {
        setError(t('categories.subcollectionNotFound') || 'Subcollection not found');
      }
    } catch (err) {
      console.error('Failed to fetch subcollection:', err);
      setError(t('categories.fetchError') || 'Failed to load subcollection');
    } finally {
      setLoading(false);
    }
  }, [subcollectionId, collectionId, t]);

  useEffect(() => {
    if (open) {
      if (isEditMode) {
        fetchSubcollection();
      } else {
        setFormData(initialFormData);
        setImageState(initialImageState);
      }
    } else {
      setFormData(initialFormData);
      setImageState(prev => {
        if (prev.previewUrl) {
          URL.revokeObjectURL(prev.previewUrl);
        }
        return initialImageState;
      });
      setError(null);
    }
  }, [open, isEditMode, fetchSubcollection]);

  useEffect(() => {
    return () => {
      if (imageState.previewUrl) {
        URL.revokeObjectURL(imageState.previewUrl);
      }
    };
  }, []);

  const handleChange = (field: keyof FormData, value: unknown) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleFileSelect = (files: FileList | null) => {
    if (!files || files.length === 0) return;

    const file = files[0];
    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    const maxSize = 10 * 1024 * 1024;

    if (!validTypes.includes(file.type)) {
      setError(t('categories.invalidImageType') || 'Invalid file type. Please upload JPEG, PNG, GIF, or WebP.');
      return;
    }

    if (file.size > maxSize) {
      setError(t('categories.imageTooLarge') || 'File too large. Maximum size is 10MB.');
      return;
    }

    if (imageState.previewUrl) {
      URL.revokeObjectURL(imageState.previewUrl);
    }

    setImageState({
      url: '',
      file,
      previewUrl: URL.createObjectURL(file),
      uploading: false,
      uploadProgress: 0,
    });
    setError(null);
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
    if (imageState.previewUrl) {
      URL.revokeObjectURL(imageState.previewUrl);
    }
    setImageState(initialImageState);
  };

  const isFormValid = (): boolean => {
    return !!formData.name.trim();
  };

  const handleSubmit = async () => {
    if (!isFormValid()) {
      setError(t('categories.validationError') || 'Please fill in all required fields');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      let finalImageUrl = imageState.url;
      const uploadId = subcollectionId || `temp-${Date.now()}`;

      if (imageState.file) {
        setImageState(prev => ({ ...prev, uploading: true, uploadProgress: 0 }));

        try {
          finalImageUrl = await categoryApi.uploadSubcollectionImage(
            uploadId,
            imageState.file,
            (progress) => {
              setImageState(prev => ({ ...prev, uploadProgress: progress }));
            }
          );
          setImageState(prev => ({
            ...prev,
            url: finalImageUrl,
            uploading: false,
            uploadProgress: 100,
          }));
        } catch (uploadErr) {
          console.error('Failed to upload image:', uploadErr);
          setImageState(prev => ({ ...prev, uploading: false }));
          throw new Error(t('categories.imageUploadError') || 'Failed to upload image');
        }
      }

      const subcollectionData = {
        name: formData.name.trim(),
        imageUrl: finalImageUrl || undefined,
        displayOrder: formData.displayOrder,
        isActive: formData.isActive,
      };

      if (isEditMode && subcollectionId) {
        await categoryApi.updateSubcollection(subcollectionId, subcollectionData);
      } else {
        await categoryApi.createSubcollection(collectionId, subcollectionData);
      }

      onSuccess();
      onClose();
    } catch (err) {
      console.error('Failed to save subcollection:', err);
      setError(
        err instanceof Error
          ? err.message
          : isEditMode
            ? (t('categories.subcollectionUpdateError') || 'Failed to update subcollection')
            : (t('categories.subcollectionCreateError') || 'Failed to create subcollection')
      );
    } finally {
      setSaving(false);
    }
  };

  const getTitle = () => {
    if (isEditMode) {
      return t('categories.editSubcollection') || 'Edit Subcollection';
    }
    return collectionName
      ? (t('categories.addSubcollectionTo', { collection: collectionName }) || `Add Subcollection to ${collectionName}`)
      : (t('categories.addSubcollection') || 'Add Subcollection');
  };

  const displayImageUrl = imageState.previewUrl || imageState.url;

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
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
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, py: 1 }}>
            {error && (
              <Alert severity="error" onClose={() => setError(null)}>
                {error}
              </Alert>
            )}

            {collectionName && (
              <Alert severity="info" sx={{ py: 0.5 }}>
                {t('categories.parentCollection') || 'Parent Collection'}: <strong>{collectionName}</strong>
              </Alert>
            )}

            <TextField
              label={t('categories.subcollectionName') || 'Subcollection Name'}
              value={formData.name}
              onChange={(e) => handleChange('name', e.target.value)}
              required
              fullWidth
              size="small"
              placeholder={t('categories.subcollectionNamePlaceholder') || 'Enter subcollection name'}
            />

            <Box>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                {t('categories.subcollectionImage') || 'Subcollection Image'}
              </Typography>

              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/gif,image/webp"
                style={{ display: 'none' }}
                onChange={(e) => handleFileSelect(e.target.files)}
              />

              {displayImageUrl ? (
                <Box
                  sx={{
                    position: 'relative',
                    width: '100%',
                    maxWidth: 160,
                    mx: 'auto',
                  }}
                >
                  <Box
                    sx={{
                      width: '100%',
                      paddingBottom: '100%',
                      position: 'relative',
                      borderRadius: 2,
                      overflow: 'hidden',
                      border: 1,
                      borderColor: 'divider',
                    }}
                  >
                    <Box
                      component="img"
                      src={displayImageUrl}
                      alt="Subcollection"
                      sx={{
                        position: 'absolute',
                        top: 0,
                        left: 0,
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                      }}
                    />
                    {imageState.uploading && (
                      <Box
                        sx={{
                          position: 'absolute',
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          bgcolor: 'rgba(0,0,0,0.5)',
                          display: 'flex',
                          flexDirection: 'column',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        <CircularProgress size={32} sx={{ color: 'white', mb: 1 }} />
                        <Typography variant="caption" sx={{ color: 'white' }}>
                          {Math.round(imageState.uploadProgress)}%
                        </Typography>
                      </Box>
                    )}
                  </Box>
                  {!imageState.uploading && (
                    <IconButton
                      size="small"
                      onClick={removeImage}
                      sx={{
                        position: 'absolute',
                        top: -8,
                        right: -8,
                        bgcolor: 'error.main',
                        color: 'white',
                        '&:hover': { bgcolor: 'error.dark' },
                      }}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  )}
                  {imageState.uploading && (
                    <LinearProgress
                      variant="determinate"
                      value={imageState.uploadProgress}
                      sx={{ mt: 1, borderRadius: 1 }}
                    />
                  )}
                </Box>
              ) : (
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
                  <CloudUploadIcon sx={{ fontSize: 40, color: 'grey.400', mb: 1 }} />
                  <Typography variant="body2" color="text.secondary">
                    {t('categories.dragDropImage') || 'Drag and drop an image here, or click to select'}
                  </Typography>
                  <Typography variant="caption" color="text.disabled" sx={{ mt: 0.5, display: 'block' }}>
                    {t('categories.supportedFormats') || 'JPEG, PNG, GIF, WebP (max 10MB)'}
                  </Typography>
                </Box>
              )}
            </Box>

            <TextField
              label={t('common.displayOrder') || 'Display Order'}
              type="number"
              value={formData.displayOrder}
              onChange={(e) => handleChange('displayOrder', parseInt(e.target.value) || 0)}
              fullWidth
              size="small"
              inputProps={{ min: 0 }}
              helperText={t('categories.displayOrderHelp') || 'Lower numbers appear first'}
            />

            <FormControlLabel
              control={
                <Switch
                  checked={formData.isActive}
                  onChange={(e) => handleChange('isActive', e.target.checked)}
                  color="primary"
                />
              }
              label={t('common.active')}
            />
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} disabled={saving || imageState.uploading}>
          {t('common.cancel')}
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={saving || loading || imageState.uploading || !isFormValid()}
          startIcon={saving ? <CircularProgress size={16} /> : <SaveIcon />}
        >
          {saving ? t('common.saving') : t('common.save')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default SubcollectionFormModal;
