import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Alert,
  CircularProgress,
  Avatar,
  FormControl,
  FormControlLabel,
  Radio,
  RadioGroup,
} from '@mui/material';
import {
  Warning as WarningIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { productService } from '../services/api';
import { useToast } from '../contexts/ToastContext';

const DeleteProductDialog = ({ open, onClose, product, onProductDeleted }) => {
  const { showSuccess } = useToast();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [deleteType, setDeleteType] = useState('soft'); // 'soft' or 'hard'

  const handleDelete = async () => {
    try {
      setLoading(true);
      setError(null);

      const isHardDelete = deleteType === 'hard';

      // Call the API with appropriate delete type
      await productService.deleteProduct(product.id, isHardDelete);
      console.log(`Product ${isHardDelete ? 'permanently' : 'soft'} deleted successfully:`, product.id);

      const message = isHardDelete
        ? `Product "${product.title}" permanently deleted! SKU "${product.sku}" is now available for reuse.`
        : `Product "${product.title}" deactivated successfully!`;

      showSuccess(message);

      // Notify parent component and close dialog
      onProductDeleted();
      onClose();

    } catch (err) {
      console.error('Error deleting product:', err);
      setError(err.message || 'Failed to delete product');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setError(null);
      onClose();
    }
  };

  if (!product) return null;

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: { borderRadius: '12px' }
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <WarningIcon color="error" sx={{ fontSize: 32 }} />
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            Delete Product
          </Typography>
        </Box>
      </DialogTitle>

      <DialogContent sx={{ pt: 6, pb: 2 }}>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ textAlign: 'center', py: 2 }}>
          {/* Product Preview */}
          <Avatar
            src={product.image_urls?.[0]}
            alt={product.title}
            sx={{ 
              width: 80, 
              height: 80, 
              mx: 'auto', 
              mb: 2,
              border: '2px solid #e0e0e0'
            }}
            variant="rounded"
          />

          <Typography variant="h6" gutterBottom sx={{ fontWeight: 600 }}>
            {product.title}
          </Typography>
          
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            SKU: {product.sku}
          </Typography>

          <Alert severity="warning" sx={{ textAlign: 'left', mb: 2 }}>
            <Typography variant="body2">
              <strong>Warning:</strong> Choose your deletion method carefully:
            </Typography>
          </Alert>

          {/* Delete Type Selection */}
          <Box sx={{ textAlign: 'left', mb: 3, p: 2, border: '1px solid #e0e0e0', borderRadius: 2 }}>
            <Typography variant="subtitle2" sx={{ mb: 2, fontWeight: 600 }}>
              Deletion Method:
            </Typography>

            <FormControl component="fieldset">
              <RadioGroup
                value={deleteType}
                onChange={(e) => setDeleteType(e.target.value)}
              >
                <FormControlLabel
                  value="soft"
                  control={<Radio />}
                  label={
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        Deactivate Product (Recommended)
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        Hides product from customers but preserves data and SKU reservation
                      </Typography>
                    </Box>
                  }
                />
                <FormControlLabel
                  value="hard"
                  control={<Radio />}
                  label={
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 500, color: 'error.main' }}>
                        Permanently Delete (Irreversible)
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        Completely removes product and frees SKU "{product.sku}" for reuse
                      </Typography>
                    </Box>
                  }
                />
              </RadioGroup>
            </FormControl>
          </Box>

          <Typography variant="body1" sx={{ fontWeight: 500 }}>
            Are you sure you want to {deleteType === 'hard' ? 'permanently delete' : 'deactivate'} this product?
          </Typography>
        </Box>
      </DialogContent>

      <DialogActions sx={{ p: 3, pt: 1 }}>
        <Button 
          onClick={handleClose} 
          disabled={loading}
          variant="outlined"
        >
          Cancel
        </Button>
        
        <Button
          onClick={handleDelete}
          disabled={loading}
          variant="contained"
          color="error"
          startIcon={loading ? <CircularProgress size={20} /> : <DeleteIcon />}
          sx={{
            '&:hover': {
              backgroundColor: '#d32f2f',
            }
          }}
        >
          {loading
            ? (deleteType === 'hard' ? 'Permanently Deleting...' : 'Deactivating...')
            : (deleteType === 'hard' ? 'Permanently Delete' : 'Deactivate Product')
          }
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default DeleteProductDialog;
