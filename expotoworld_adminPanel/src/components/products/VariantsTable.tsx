/**
 * VariantsTable Component
 * 
 * Matrix view for managing product variants (child products).
 * Shows all variants in a table with inline editing capabilities.
 * 
 * Features:
 * - Display all variants with their option values
 * - Inline editing for price, stock, SKU
 * - Bulk selection and actions
 * - Generate missing variants button
 * - Individual variant edit/delete actions
 */
import React, { useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Typography,
  Button,
  IconButton,
  Checkbox,
  TextField,
  InputAdornment,
  Chip,
  Tooltip,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  CircularProgress,
  Alert,
  Avatar,
  Stack,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  PriceChange as PriceChangeIcon,
  Inventory as InventoryIcon,
  Refresh as RefreshIcon,
  Star as StarIcon,
  StarBorder as StarBorderIcon,
  Image as ImageIcon,
} from '@mui/icons-material';
import type { Product, ProductAttribute } from '@/services/catalogApi';
import type { VariationOption } from './VariationOptionsEditor';

// Represents a variant row in the table
interface VariantRow {
  id: string;
  productId: number;
  sku: string;
  price: number;
  strikethroughPrice?: number;
  stock: number;
  isActive: boolean;
  isDefaultVariant: boolean;
  imageUrl?: string;
  attributes: Record<string, string>; // e.g., { "Color": "Red", "Size": "M" }
}

interface VariantsTableProps {
  /** Parent product ID */
  parentId: string;
  /** Variation options defined on parent */
  variationOptions: VariationOption[];
  /** List of child variants */
  variants: Product[];
  /** Callback to open variant editor modal */
  onEditVariant: (variantId: string) => void;
  /** Callback to delete a variant */
  onDeleteVariant: (variantId: string) => Promise<void>;
  /** Callback to generate all missing variants */
  onGenerateVariants: () => Promise<void>;
  /** Callback for bulk price update */
  onBulkPriceUpdate: (variantIds: string[], price: number) => Promise<void>;
  /** Callback for bulk stock update */
  onBulkStockUpdate: (variantIds: string[], stock: number) => Promise<void>;
  /** Callback to set default variant */
  onSetDefaultVariant: (variantId: string) => Promise<void>;
  /** Callback to inline update a single field */
  onInlineUpdate?: (variantId: string, field: string, value: unknown) => Promise<void>;
  /** Whether operations are in progress */
  loading?: boolean;
  /** Refresh variants list */
  onRefresh?: () => void;
}

export const VariantsTable: React.FC<VariantsTableProps> = ({
  parentId: _parentId,
  variationOptions,
  variants,
  onEditVariant,
  onDeleteVariant,
  onGenerateVariants,
  onBulkPriceUpdate,
  onBulkStockUpdate,
  onSetDefaultVariant,
  onInlineUpdate: _onInlineUpdate,
  loading = false,
  onRefresh,
}) => {
  const { t } = useTranslation();
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [bulkMenuAnchor, setBulkMenuAnchor] = useState<null | HTMLElement>(null);
  const [bulkPriceDialogOpen, setBulkPriceDialogOpen] = useState(false);
  const [bulkStockDialogOpen, setBulkStockDialogOpen] = useState(false);
  const [bulkPriceValue, setBulkPriceValue] = useState<string>('');
  const [bulkStockValue, setBulkStockValue] = useState<string>('');
  const [generating, setGenerating] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  // Convert variants to table rows
  const variantRows: VariantRow[] = useMemo(() => {
    return variants.map((variant) => {
      // Extract attribute values
      const attributes: Record<string, string> = {};
      variant.attributes?.forEach((attr: ProductAttribute) => {
        if (attr.attributeName) {
          attributes[attr.attributeName] = attr.attributeValue || '';
        }
      });

      return {
        id: variant.id,
        productId: parseInt(variant.id),
        sku: variant.sku || '',
        price: variant.currentPrice,
        strikethroughPrice: variant.originalPrice !== variant.currentPrice ? variant.originalPrice : undefined,
        stock: variant.stockLeft,
        isActive: variant.isActive,
        isDefaultVariant: variant.isDefaultVariant || false,
        imageUrl: variant.primaryImageUrl || variant.imageUrls?.[0],
        attributes,
      };
    });
  }, [variants]);

  // Calculate how many variants are possible vs how many exist
  const totalPossibleVariants = useMemo(() => {
    if (variationOptions.length === 0) return 0;
    return variationOptions.reduce((total, option) => {
      const count = option.values.length;
      return total === 0 ? count : total * (count || 1);
    }, 0);
  }, [variationOptions]);

  const missingVariantsCount = totalPossibleVariants - variantRows.length;

  // Get option columns for the table header
  const optionColumns = variationOptions.map(opt => opt.name).filter(Boolean);

  // Handle select all
  const handleSelectAll = useCallback((checked: boolean) => {
    if (checked) {
      setSelectedIds(new Set(variantRows.map(r => r.id)));
    } else {
      setSelectedIds(new Set());
    }
  }, [variantRows]);

  // Handle individual select
  const handleSelect = useCallback((id: string, checked: boolean) => {
    setSelectedIds(prev => {
      const next = new Set(prev);
      if (checked) {
        next.add(id);
      } else {
        next.delete(id);
      }
      return next;
    });
  }, []);

  // Handle generate variants
  const handleGenerate = useCallback(async () => {
    setGenerating(true);
    try {
      await onGenerateVariants();
    } finally {
      setGenerating(false);
    }
  }, [onGenerateVariants]);

  // Handle delete
  const handleDelete = useCallback(async (id: string) => {
    setDeletingId(id);
    try {
      await onDeleteVariant(id);
    } finally {
      setDeletingId(null);
    }
  }, [onDeleteVariant]);

  // Handle bulk actions
  const handleBulkPriceUpdate = useCallback(async () => {
    const price = parseFloat(bulkPriceValue);
    if (isNaN(price) || price < 0) return;
    
    await onBulkPriceUpdate(Array.from(selectedIds), price);
    setBulkPriceDialogOpen(false);
    setBulkPriceValue('');
    setSelectedIds(new Set());
    setBulkMenuAnchor(null);
  }, [selectedIds, bulkPriceValue, onBulkPriceUpdate]);

  const handleBulkStockUpdate = useCallback(async () => {
    const stock = parseInt(bulkStockValue);
    if (isNaN(stock) || stock < 0) return;
    
    await onBulkStockUpdate(Array.from(selectedIds), stock);
    setBulkStockDialogOpen(false);
    setBulkStockValue('');
    setSelectedIds(new Set());
    setBulkMenuAnchor(null);
  }, [selectedIds, bulkStockValue, onBulkStockUpdate]);

  const allSelected = variantRows.length > 0 && selectedIds.size === variantRows.length;
  const someSelected = selectedIds.size > 0 && selectedIds.size < variantRows.length;

  return (
    <Card variant="outlined">
      <CardContent>
        {/* Header */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Box>
            <Typography variant="subtitle1" fontWeight={600}>
              {t('products.form.variants', 'Variants')}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {variantRows.length} / {totalPossibleVariants} {t('products.form.variantsCreated', 'variants created')}
            </Typography>
          </Box>
          <Stack direction="row" spacing={1}>
            {onRefresh && (
              <Tooltip title={t('common.refresh', 'Refresh')}>
                <IconButton size="small" onClick={onRefresh} disabled={loading}>
                  <RefreshIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            {missingVariantsCount > 0 && (
              <Button
                size="small"
                variant="contained"
                startIcon={generating ? <CircularProgress size={16} color="inherit" /> : <AddIcon />}
                onClick={handleGenerate}
                disabled={loading || generating}
              >
                {t('products.form.generateVariants', `Generate ${missingVariantsCount} Variants`, { count: missingVariantsCount })}
              </Button>
            )}
          </Stack>
        </Box>

        {/* Bulk actions bar */}
        {selectedIds.size > 0 && (
          <Alert 
            severity="info" 
            sx={{ mb: 2 }}
            action={
              <Button
                size="small"
                color="inherit"
                onClick={(e) => setBulkMenuAnchor(e.currentTarget)}
              >
                {t('products.form.bulkActions', 'Bulk Actions')}
              </Button>
            }
          >
            {t('products.form.selectedCount', `${selectedIds.size} variant(s) selected`, { count: selectedIds.size })}
          </Alert>
        )}

        {/* Bulk actions menu */}
        <Menu
          anchorEl={bulkMenuAnchor}
          open={Boolean(bulkMenuAnchor)}
          onClose={() => setBulkMenuAnchor(null)}
        >
          <MenuItem onClick={() => setBulkPriceDialogOpen(true)}>
            <ListItemIcon><PriceChangeIcon fontSize="small" /></ListItemIcon>
            <ListItemText>{t('products.form.setPrice', 'Set Price')}</ListItemText>
          </MenuItem>
          <MenuItem onClick={() => setBulkStockDialogOpen(true)}>
            <ListItemIcon><InventoryIcon fontSize="small" /></ListItemIcon>
            <ListItemText>{t('products.form.setStock', 'Set Stock')}</ListItemText>
          </MenuItem>
        </Menu>

        {/* Bulk price dialog */}
        {bulkPriceDialogOpen && (
          <Paper sx={{ p: 2, mb: 2, backgroundColor: 'action.hover' }}>
            <Typography variant="body2" gutterBottom>
              {t('products.form.setPriceFor', `Set price for ${selectedIds.size} variant(s)`, { count: selectedIds.size })}
            </Typography>
            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
              <TextField
                size="small"
                type="number"
                value={bulkPriceValue}
                onChange={(e) => setBulkPriceValue(e.target.value)}
                InputProps={{
                  startAdornment: <InputAdornment position="start">$</InputAdornment>,
                }}
                sx={{ width: 150 }}
              />
              <Button size="small" variant="contained" onClick={handleBulkPriceUpdate}>
                {t('common.apply', 'Apply')}
              </Button>
              <Button size="small" onClick={() => setBulkPriceDialogOpen(false)}>
                {t('common.cancel', 'Cancel')}
              </Button>
            </Box>
          </Paper>
        )}

        {/* Bulk stock dialog */}
        {bulkStockDialogOpen && (
          <Paper sx={{ p: 2, mb: 2, backgroundColor: 'action.hover' }}>
            <Typography variant="body2" gutterBottom>
              {t('products.form.setStockFor', `Set stock for ${selectedIds.size} variant(s)`, { count: selectedIds.size })}
            </Typography>
            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
              <TextField
                size="small"
                type="number"
                value={bulkStockValue}
                onChange={(e) => setBulkStockValue(e.target.value)}
                sx={{ width: 150 }}
              />
              <Button size="small" variant="contained" onClick={handleBulkStockUpdate}>
                {t('common.apply', 'Apply')}
              </Button>
              <Button size="small" onClick={() => setBulkStockDialogOpen(false)}>
                {t('common.cancel', 'Cancel')}
              </Button>
            </Box>
          </Paper>
        )}

        {/* No variants message */}
        {variantRows.length === 0 ? (
          <Paper
            variant="outlined"
            sx={{
              p: 4,
              textAlign: 'center',
              backgroundColor: 'action.hover',
              borderStyle: 'dashed',
            }}
          >
            <Typography variant="body2" color="text.secondary" gutterBottom>
              {t('products.form.noVariantsYet', 'No variants created yet')}
            </Typography>
            {missingVariantsCount > 0 && (
              <Button
                variant="outlined"
                size="small"
                startIcon={<AddIcon />}
                onClick={handleGenerate}
                disabled={generating}
                sx={{ mt: 1 }}
              >
                {t('products.form.generateAllVariants', `Generate All ${totalPossibleVariants} Variants`, { count: totalPossibleVariants })}
              </Button>
            )}
            {totalPossibleVariants === 0 && (
              <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
                {t('products.form.defineOptionsFirst', 'Define variation options above first')}
              </Typography>
            )}
          </Paper>
        ) : (
          /* Variants table */
          <TableContainer component={Paper} variant="outlined">
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell padding="checkbox">
                    <Checkbox
                      indeterminate={someSelected}
                      checked={allSelected}
                      onChange={(e) => handleSelectAll(e.target.checked)}
                    />
                  </TableCell>
                  <TableCell sx={{ width: 50 }}></TableCell>
                  {optionColumns.map((col) => (
                    <TableCell key={col}>{col}</TableCell>
                  ))}
                  <TableCell>{t('products.sku', 'SKU')}</TableCell>
                  <TableCell align="right">{t('products.price', 'Price')}</TableCell>
                  <TableCell align="right">{t('products.stock', 'Stock')}</TableCell>
                  <TableCell align="center">{t('products.status', 'Status')}</TableCell>
                  <TableCell align="right">{t('common.actions', 'Actions')}</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {variantRows.map((row) => (
                  <TableRow 
                    key={row.id}
                    hover
                    sx={{ 
                      '&:last-child td, &:last-child th': { border: 0 },
                      opacity: row.isActive ? 1 : 0.6,
                    }}
                  >
                    <TableCell padding="checkbox">
                      <Checkbox
                        checked={selectedIds.has(row.id)}
                        onChange={(e) => handleSelect(row.id, e.target.checked)}
                      />
                    </TableCell>
                    <TableCell>
                      {row.imageUrl ? (
                        <Avatar
                          variant="rounded"
                          src={row.imageUrl}
                          sx={{ width: 40, height: 40 }}
                        >
                          <ImageIcon />
                        </Avatar>
                      ) : (
                        <Avatar
                          variant="rounded"
                          sx={{ width: 40, height: 40, bgcolor: 'action.hover' }}
                        >
                          <ImageIcon sx={{ color: 'text.disabled' }} />
                        </Avatar>
                      )}
                    </TableCell>
                    {optionColumns.map((col) => (
                      <TableCell key={col}>
                        <Chip
                          label={row.attributes[col] || '-'}
                          size="small"
                          variant="outlined"
                        />
                      </TableCell>
                    ))}
                    <TableCell>
                      <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                        {row.sku || '-'}
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Box>
                        <Typography variant="body2" fontWeight={500}>
                          ${row.price.toFixed(2)}
                        </Typography>
                        {row.strikethroughPrice && (
                          <Typography variant="caption" color="text.secondary" sx={{ textDecoration: 'line-through' }}>
                            ${row.strikethroughPrice.toFixed(2)}
                          </Typography>
                        )}
                      </Box>
                    </TableCell>
                    <TableCell align="right">
                      <Typography 
                        variant="body2"
                        color={row.stock <= 0 ? 'error.main' : row.stock <= 10 ? 'warning.main' : 'text.primary'}
                      >
                        {row.stock}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0.5 }}>
                        {row.isDefaultVariant && (
                          <Tooltip title={t('products.form.defaultVariant', 'Default Variant')}>
                            <StarIcon sx={{ fontSize: 16, color: 'warning.main' }} />
                          </Tooltip>
                        )}
                        <Chip
                          label={row.isActive ? t('common.active', 'Active') : t('common.inactive', 'Inactive')}
                          size="small"
                          color={row.isActive ? 'success' : 'default'}
                        />
                      </Box>
                    </TableCell>
                    <TableCell align="right">
                      <Stack direction="row" spacing={0.5} justifyContent="flex-end">
                        {!row.isDefaultVariant && (
                          <Tooltip title={t('products.form.setAsDefault', 'Set as Default')}>
                            <IconButton
                              size="small"
                              onClick={() => onSetDefaultVariant(row.id)}
                            >
                              <StarBorderIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        )}
                        <Tooltip title={t('common.edit', 'Edit')}>
                          <IconButton
                            size="small"
                            onClick={() => onEditVariant(row.id)}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title={t('common.delete', 'Delete')}>
                          <IconButton
                            size="small"
                            color="error"
                            onClick={() => handleDelete(row.id)}
                            disabled={deletingId === row.id}
                          >
                            {deletingId === row.id ? (
                              <CircularProgress size={16} />
                            ) : (
                              <DeleteIcon fontSize="small" />
                            )}
                          </IconButton>
                        </Tooltip>
                      </Stack>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </CardContent>
    </Card>
  );
};

export default VariantsTable;
