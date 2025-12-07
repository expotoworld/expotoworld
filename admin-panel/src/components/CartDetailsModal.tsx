import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Grid,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Divider,
  TextField,
  IconButton,
  Alert,
} from '@mui/material';
import {
  Close as CloseIcon,
  Edit as EditIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { cartService } from '../services/api';
import { CartDetails, CartItemDetail } from '../types/domain';

interface CartDetailsModalProps {
  open: boolean;
  onClose: () => void;
  cart: CartDetails | null;
  onUpdate: () => void;
}

import { useToast } from '../contexts/ToastContext';

const CartDetailsModal: React.FC<CartDetailsModalProps> = ({ open, onClose, cart, onUpdate }) => {
  const [editingItem, setEditingItem] = useState<string | null>(null);
  const [newQuantity, setNewQuantity] = useState<string>('');
  const [updating, setUpdating] = useState<boolean>(false);

  const { showToast } = useToast();

  const miniAppTypeLabels: Record<string, string> = {
    // ETW types (primary)
    ETWtoB: 'EXPO to WORLD to B',
    ETWtoU: 'EXPO to WORLD to U',
    ETWtoC: 'EXPO to WORLD to C',
    ETWtoX: 'EXPO to WORLD to X',
  };

  const miniAppTypeColors: Record<string, string> = {
    // ETW types (primary)
    ETWtoB: '#520ee6',
    ETWtoU: '#2196f3',
    ETWtoC: '#ffd556',
    ETWtoX: '#076200',
  };

  const handleStartEdit = (item: Pick<CartItemDetail, 'id' | 'quantity'>): void => {
    setEditingItem(item.id);
    setNewQuantity(item.quantity.toString());
  };

  const handleCancelEdit = () => {
    setEditingItem(null);
    setNewQuantity('');
  };

  const handleSaveQuantity = async (item: Pick<CartItemDetail, 'id' | 'product_id' | 'quantity'>): Promise<void> => {
    if (!newQuantity || newQuantity === item.quantity.toString()) {
      handleCancelEdit();
      return;
    }

    const quantity = parseInt(newQuantity, 10);
    if (Number.isNaN(quantity) || quantity < 0) {
      showToast('Please enter a valid quantity', 'error');
      return;
    }

    try {
      setUpdating(true);
      if (!cart) return;
      await cartService.updateCartItem(String(cart.cart.id), item.product_id, quantity);
      showToast('Cart item updated successfully', 'success');
      handleCancelEdit();
      onUpdate(); // Refresh the cart list
      onClose(); // Close the modal to refresh data
    } catch (err) {
      console.error('Error updating cart item:', err);
      showToast('Failed to update cart item', 'error');
    } finally {
      setUpdating(false);
    }
  };

  const handleRemoveItem = async (item: Pick<CartItemDetail, 'product_id'>): Promise<void> => {
    try {
      setUpdating(true);
      if (!cart) return;
      await cartService.updateCartItem(String(cart.cart.id), item.product_id, 0);
      showToast('Item removed from cart', 'success');
      onUpdate(); // Refresh the cart list
      onClose(); // Close the modal to refresh data
    } catch (err) {
      console.error('Error removing cart item:', err);
      showToast('Failed to remove cart item', 'error');
    } finally {
      setUpdating(false);
    }
  };

  const formatCurrency = (amount: number): string => {
    return new Intl.NumberFormat('zh-CN', {
      style: 'currency',
      currency: 'CNY',
    }).format(amount);
  };

  const formatDate = (dateString: string): string => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (!cart) return null;

  const { cart: cartInfo, items } = cart;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Typography variant="h6">Cart Details</Typography>
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>

      <DialogContent dividers>
        {/* Cart Information */}
        <Box sx={{ mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            Cart Information
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Cart ID
                </Typography>
                <Typography variant="body1" fontFamily="monospace">
                  {cartInfo.id}
                </Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  User
                </Typography>
                <Typography variant="body1">
                  {cartInfo.user_name || 'Unknown User'}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {cartInfo.user_email}
                </Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Mini-App Type
                </Typography>
                <Chip
                  label={miniAppTypeLabels[cartInfo.mini_app_type as keyof typeof miniAppTypeLabels] || cartInfo.mini_app_type}
                  size="small"
                  sx={{
                    backgroundColor:
                      miniAppTypeColors[cartInfo.mini_app_type as keyof typeof miniAppTypeColors] || '#gray',
                    color: 'white',
                    fontWeight: 500,
                  }}
                />
              </Box>
            </Grid>
            <Grid item xs={12} md={6}>
              {cartInfo.store_name && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Store
                  </Typography>
                  <Typography variant="body1">
                    {cartInfo.store_name}
                  </Typography>
                </Box>
              )}
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Total Items
                </Typography>
                <Typography variant="body1" fontWeight={500}>
                  {cartInfo.item_count}
                </Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Total Value
                </Typography>
                <Typography variant="h6" color="primary" fontWeight={600}>
                  {formatCurrency(cartInfo.total_value)}
                </Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  Last Updated
                </Typography>
                <Typography variant="body1">
                  {formatDate(cartInfo.updated_at)}
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </Box>

        <Divider sx={{ my: 3 }} />

        {/* Cart Items */}
        <Box>
          <Typography variant="h6" gutterBottom>
            Cart Items
          </Typography>

          {updating && (
            <Alert severity="info" sx={{ mb: 2 }}>
              Updating cart item...
            </Alert>
          )}

          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Product</TableCell>
                  <TableCell align="center">Quantity</TableCell>
                  <TableCell align="right">Unit Price</TableCell>
                  <TableCell align="right">Total Price</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {items.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell>
                      <Box>
                        <Typography variant="body2" fontWeight={500}>
                          {item.product?.title || 'Unknown Product'}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          SKU: {item.product?.sku || 'N/A'}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell align="center">
                      {editingItem === item.id ? (
                        <Box display="flex" alignItems="center" justifyContent="center" gap={1}>
                          <TextField
                            size="small"
                            type="number"
                            value={newQuantity}
                            onChange={(e) => setNewQuantity(e.target.value)}
                            inputProps={{ min: 0, style: { textAlign: 'center' } }}
                            sx={{ width: 80 }}
                          />
                          <IconButton
                            size="small"
                            onClick={() => handleSaveQuantity(item)}
                            color="primary"
                            disabled={updating}
                          >
                            <SaveIcon />
                          </IconButton>
                          <IconButton
                            size="small"
                            onClick={handleCancelEdit}
                            disabled={updating}
                          >
                            <CancelIcon />
                          </IconButton>
                        </Box>
                      ) : (
                        <Box display="flex" alignItems="center" justifyContent="center" gap={1}>
                          <Typography variant="body2" fontWeight={500}>
                            {item.quantity}
                          </Typography>
                          <IconButton
                            size="small"
                            onClick={() => handleStartEdit(item)}
                            disabled={updating}
                          >
                            <EditIcon />
                          </IconButton>
                        </Box>
                      )}
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2">
                        {formatCurrency(item.product?.main_price || 0)}
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" fontWeight={500}>
                        {formatCurrency((item.product?.main_price || 0) * item.quantity)}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <IconButton
                        size="small"
                        onClick={() => handleRemoveItem(item)}
                        color="error"
                        disabled={updating}
                      >
                        <DeleteIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Box>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Close</Button>
      </DialogActions>
    </Dialog>
  );
};

export default CartDetailsModal;
