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
import {
  categoryApi,
  type Collection,
} from '@/services/catalogApi';

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

interface CollectionFormModalProps {
  open: boolean;
  subcategoryId: string;
  subcategoryName?: string;
  collectionId?: string;
  onClose: () => void;
  onSuccess: () => void;
}

const CollectionFormModal: React.FC<CollectionFormModalProps> = ({
  open,
  subcategoryId,
  subcategoryName,
  collectionId,
  onClose,
  onSuccess,
}) => {
  const { t } = useTranslation();
  const isEditMode = !!collectionId;
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Form state
  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [imageState, setImageState] = useState<ImageState>(initialImageState);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [dragOver, setDragOver] = useState(false);

  // Fetch collection data for edit mode
  const fetchCollection = useCallback(async () => {
    if (!collectionId) return;
    
    setLoading(true);
    setError(null);
    try {
      const collections = await categoryApi.getCollections(subcategoryId);
      const collection = collections.find(col => col.id === collectionId);
      
      if (collection) {
        setFormData({
          name: collection.name || '',
          displayOrder: collection.displayOrder ?? 0,
          isActive: collection.isActive ?? true,
        });
        setImageState({
          url: collection.imageUrl || '',
          uploading: false,
          uploadProgress: 0,
        });
      } else {
        setError(t('categories.collectionNotFound') || 'Collection not found');
      }
    } catch (err) {
      console.error('Failed to fetch collection:', err);
      setError(t('categories.fetchError') || 'Failed to load collection');
    } finally {
      setLoading(false);
    }
  }, [collectionId, subcategoryId, t]);

  // Initialize when modal opens
  useEffect(() => {
    if (open) {
      if (isEditMode) {
        fetchCollection();
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
  }, [open, isEditMode, fetchCollection]);

  // Clean up preview URLs on unmount
  useEffect(() => {
    return () => {
      if (imageState.previewUrl) {
        URL.revokeObjectURL(imageState.previewUrl);
      }
    };
  }, []);

  // Handle form field changes
  const handleChange = (field: keyof FormData, value: unknown) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  // Handle file selection
  const handleFileSelect = (files: FileList | null) => {
    if (!files || files.length === 0) return;
    
    const file = files[0];
    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    const maxSize = 10 * 1024 * 1024; // 10MB
    
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

  // Drag and drop handlers
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

  // Remove image
  const removeImage = () => {
    if (imageState.previewUrl) {
      URL.revokeObjectURL(imageState.previewUrl);
    }
    setImageState(initialImageState);
  };

  // Validate form
  const isFormValid = (): boolean => {
    return !!formData.name.trim();
  };

  // Handle form submission
  const handleSubmit = async () => {
    if (!isFormValid()) {
      setError(t('categories.validationError') || 'Please fill in all required fields');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      let finalImageUrl = imageState.url;
      const uploadId = collectionId || `temp-${Date.now()}`;

      // Upload image if there's a pending file
      if (imageState.file) {
        setImageState(prev => ({ ...prev, uploading: true, uploadProgress: 0 }));
        
        try {
          finalImageUrl = await categoryApi.uploadCollectionImage(
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
            uploadProgress: 100 
          }));
        } catch (uploadErr) {
          console.error('Failed to upload image:', uploadErr);
          setImageState(prev => ({ ...prev, uploading: false }));
          throw new Error(t('categories.imageUploadError') || 'Failed to upload image');
        }
      }

      const collectionData: Partial<Collection> = {
        name: formData.name.trim(),
        imageUrl: finalImageUrl || undefined,
        displayOrder: formData.displayOrder,
        isActive: formData.isActive,
      };

      if (isEditMode && collectionId) {
        await categoryApi.updateCollection(collectionId, collectionData);
      } else {
        await categoryApi.createCollection(subcategoryId, collectionData);
      }

      onSuccess();
      onClose();
    } catch (err) {
      console.error('Failed to save collection:', err);
      setError(
        err instanceof Error 
          ? err.message
          : isEditMode
            ? (t('categories.collectionUpdateError') || 'Failed to update collection')
            : (t('categories.collectionCreateError') || 'Failed to create collection')
      );
    } finally {
      setSaving(false);
    }
  };

  const getTitle = () => {
    if (isEditMode) {
      return t('categories.editCollection') || 'Edit Collection';
    }
    return subcategoryName 
      ? (t('categories.addCollectionTo', { subcategory: subcategoryName }) || `Add Collection to ${subcategoryName}`)
      : (t('categories.addCollection') || 'Add Collection');
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

            {/* Parent Subcategory Info */}
            {subcategoryName && (
              <Alert severity="info" sx={{ py: 0.5 }}>
                {t('categories.parentSubcategory') || 'Parent Subcategory'}: <strong>{subcategoryName}</strong>
              </Alert>
            )}

            {/* Collection Name */}
            <TextField
              label={t('categories.collectionName') || 'Collection Name'}
              value={formData.name}
              onChange={(e) => handleChange('name', e.target.value)}
              required
              fullWidth
              size="small"
              placeholder={t('categories.collectionNamePlaceholder') || 'Enter collection name'}
            />

            {/* Image Upload */}
            <Box>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                {t('categories.collectionImage') || 'Collection Image'}
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
                      alt="Collection"
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

            {/* Display Order */}
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

            {/* Active Status */}
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

export default CollectionFormModal;
