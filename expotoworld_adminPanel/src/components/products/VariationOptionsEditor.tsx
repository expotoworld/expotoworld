/**
 * VariationOptionsEditor Component
 * 
 * Visual editor for defining product variation options (e.g., Color, Size).
 * Used on parent products to define what attributes vary across child variants.
 * 
 * Features:
 * - Add/remove option names (Color, Size, Material, etc.)
 * - Add/remove option values (Red, Blue, S, M, L, etc.)
 * - Drag-to-reorder support for values
 * - Preview of total variant combinations
 * - Input via chip/tag interface for easy value management
 */
import React, { useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  IconButton,
  Typography,
  Chip,
  Stack,
  Paper,
  Divider,
  Tooltip,
  Alert,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  DragIndicator as DragIcon,
} from '@mui/icons-material';

// Type for a single variation option (e.g., Color with values [Red, Blue, Green])
export interface VariationOption {
  name: string;
  values: Array<{
    value: string;
    displayOrder: number;
  }>;
}

interface VariationOptionsEditorProps {
  /** Current variation options */
  options: VariationOption[];
  /** Callback when options change */
  onChange: (options: VariationOption[]) => void;
  /** Whether the editor is disabled (e.g., when product already has variants) */
  disabled?: boolean;
  /** Whether to show the variant count preview */
  showPreview?: boolean;
  /** Maximum number of options allowed (default: 3, like Shopify) */
  maxOptions?: number;
}

// Common option name suggestions
const OPTION_SUGGESTIONS = [
  'Color',
  'Size',
  'Material',
  'Style',
  'Pattern',
  'Weight',
  'Quantity',
  'Type',
];

export const VariationOptionsEditor: React.FC<VariationOptionsEditorProps> = ({
  options,
  onChange,
  disabled = false,
  showPreview = true,
  maxOptions = 3,
}) => {
  const { t } = useTranslation();
  const [newValueInputs, setNewValueInputs] = useState<Record<number, string>>({});

  // Calculate total variant combinations
  const calculateTotalVariants = useCallback(() => {
    if (options.length === 0) return 0;
    return options.reduce((total, option) => {
      const valueCount = option.values.length;
      return total === 0 ? valueCount : total * (valueCount || 1);
    }, 0);
  }, [options]);

  // Add a new option (e.g., "Color")
  const handleAddOption = useCallback(() => {
    if (options.length >= maxOptions) return;
    
    const newOption: VariationOption = {
      name: '',
      values: [],
    };
    onChange([...options, newOption]);
  }, [options, maxOptions, onChange]);

  // Remove an option
  const handleRemoveOption = useCallback((index: number) => {
    const newOptions = options.filter((_, i) => i !== index);
    onChange(newOptions);
    
    // Clean up the new value input state
    const newInputs = { ...newValueInputs };
    delete newInputs[index];
    setNewValueInputs(newInputs);
  }, [options, newValueInputs, onChange]);

  // Update option name
  const handleOptionNameChange = useCallback((index: number, name: string) => {
    const newOptions = [...options];
    newOptions[index] = { ...newOptions[index], name };
    onChange(newOptions);
  }, [options, onChange]);

  // Add a value to an option
  const handleAddValue = useCallback((optionIndex: number) => {
    const valueInput = newValueInputs[optionIndex]?.trim();
    if (!valueInput) return;
    
    // Check for duplicate values
    const existingValues = options[optionIndex].values.map(v => v.value.toLowerCase());
    if (existingValues.includes(valueInput.toLowerCase())) {
      return; // Don't add duplicates
    }
    
    const newOptions = [...options];
    const nextDisplayOrder = newOptions[optionIndex].values.length > 0
      ? Math.max(...newOptions[optionIndex].values.map(v => v.displayOrder)) + 1
      : 1;
    
    newOptions[optionIndex] = {
      ...newOptions[optionIndex],
      values: [
        ...newOptions[optionIndex].values,
        { value: valueInput, displayOrder: nextDisplayOrder },
      ],
    };
    
    onChange(newOptions);
    setNewValueInputs({ ...newValueInputs, [optionIndex]: '' });
  }, [options, newValueInputs, onChange]);

  // Remove a value from an option
  const handleRemoveValue = useCallback((optionIndex: number, valueIndex: number) => {
    const newOptions = [...options];
    newOptions[optionIndex] = {
      ...newOptions[optionIndex],
      values: newOptions[optionIndex].values.filter((_, i) => i !== valueIndex),
    };
    onChange(newOptions);
  }, [options, onChange]);

  // Handle Enter key in value input
  const handleValueInputKeyDown = useCallback((optionIndex: number, e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      handleAddValue(optionIndex);
    }
  }, [handleAddValue]);

  // Select a suggested option name
  const handleSelectSuggestion = useCallback((optionIndex: number, suggestion: string) => {
    handleOptionNameChange(optionIndex, suggestion);
  }, [handleOptionNameChange]);

  // Get available suggestions (not already used)
  const getAvailableSuggestions = useCallback(() => {
    const usedNames = options.map(o => o.name.toLowerCase());
    return OPTION_SUGGESTIONS.filter(s => !usedNames.includes(s.toLowerCase()));
  }, [options]);

  const totalVariants = calculateTotalVariants();
  const canAddOption = options.length < maxOptions && !disabled;

  return (
    <Card variant="outlined">
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="subtitle1" fontWeight={600}>
            {t('products.form.variationOptions', 'Variation Options')}
          </Typography>
          {canAddOption && (
            <Button
              size="small"
              startIcon={<AddIcon />}
              onClick={handleAddOption}
              disabled={disabled}
            >
              {t('products.form.addOption', 'Add Option')}
            </Button>
          )}
        </Box>

        {options.length === 0 ? (
          <Paper
            variant="outlined"
            sx={{
              p: 3,
              textAlign: 'center',
              backgroundColor: 'action.hover',
              borderStyle: 'dashed',
            }}
          >
            <Typography variant="body2" color="text.secondary" gutterBottom>
              {t('products.form.noOptionsYet', 'No variation options defined yet')}
            </Typography>
            <Typography variant="caption" color="text.secondary" display="block" sx={{ mb: 2 }}>
              {t('products.form.optionsHelp', 'Add options like Color, Size, or Material to create product variants')}
            </Typography>
            <Button
              variant="outlined"
              size="small"
              startIcon={<AddIcon />}
              onClick={handleAddOption}
              disabled={disabled}
            >
              {t('products.form.addFirstOption', 'Add First Option')}
            </Button>
          </Paper>
        ) : (
          <Stack spacing={2}>
            {options.map((option, optionIndex) => (
              <Paper
                key={optionIndex}
                variant="outlined"
                sx={{ p: 2 }}
              >
                <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1, mb: 2 }}>
                  {!disabled && (
                    <DragIcon 
                      sx={{ 
                        color: 'text.disabled', 
                        cursor: 'grab',
                        mt: 1,
                      }} 
                    />
                  )}
                  <Box sx={{ flex: 1 }}>
                    <TextField
                      fullWidth
                      size="small"
                      label={t('products.form.optionName', 'Option Name')}
                      placeholder={t('products.form.optionNamePlaceholder', 'e.g., Color, Size')}
                      value={option.name}
                      onChange={(e) => handleOptionNameChange(optionIndex, e.target.value)}
                      disabled={disabled}
                      sx={{ mb: 1 }}
                    />
                    {/* Option name suggestions */}
                    {!option.name && !disabled && (
                      <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mt: 0.5 }}>
                        <Typography variant="caption" color="text.secondary" sx={{ mr: 0.5 }}>
                          {t('products.form.suggestions', 'Suggestions:')}
                        </Typography>
                        {getAvailableSuggestions().slice(0, 5).map((suggestion) => (
                          <Chip
                            key={suggestion}
                            label={suggestion}
                            size="small"
                            variant="outlined"
                            onClick={() => handleSelectSuggestion(optionIndex, suggestion)}
                            sx={{ cursor: 'pointer', fontSize: '0.7rem', height: 20 }}
                          />
                        ))}
                      </Box>
                    )}
                  </Box>
                  {!disabled && (
                    <Tooltip title={t('products.form.removeOption', 'Remove Option')}>
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleRemoveOption(optionIndex)}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  )}
                </Box>

                <Divider sx={{ my: 1.5 }} />

                {/* Values section */}
                <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                  {t('products.form.optionValues', 'Values')}
                </Typography>
                
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5, mb: 1.5 }}>
                  {option.values.map((val, valueIndex) => (
                    <Chip
                      key={valueIndex}
                      label={val.value}
                      onDelete={disabled ? undefined : () => handleRemoveValue(optionIndex, valueIndex)}
                      size="small"
                      color="primary"
                      variant="outlined"
                    />
                  ))}
                  {option.values.length === 0 && (
                    <Typography variant="caption" color="text.secondary" fontStyle="italic">
                      {t('products.form.noValuesYet', 'No values added yet')}
                    </Typography>
                  )}
                </Box>

                {/* Add value input */}
                {!disabled && (
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <TextField
                      size="small"
                      placeholder={
                        option.name
                          ? t('products.form.addValuePlaceholder', `Add ${option.name} value`, { name: option.name })
                          : t('products.form.addValueGeneric', 'Add value')
                      }
                      value={newValueInputs[optionIndex] || ''}
                      onChange={(e) => setNewValueInputs({ ...newValueInputs, [optionIndex]: e.target.value })}
                      onKeyDown={(e) => handleValueInputKeyDown(optionIndex, e)}
                      sx={{ flex: 1 }}
                    />
                    <Button
                      size="small"
                      variant="outlined"
                      onClick={() => handleAddValue(optionIndex)}
                      disabled={!newValueInputs[optionIndex]?.trim()}
                    >
                      {t('common.add', 'Add')}
                    </Button>
                  </Box>
                )}
              </Paper>
            ))}
          </Stack>
        )}

        {/* Preview section */}
        {showPreview && options.length > 0 && (
          <>
            <Divider sx={{ my: 2 }} />
            <Alert 
              severity="info" 
              icon={false}
              sx={{ 
                backgroundColor: 'primary.50',
                '& .MuiAlert-message': { width: '100%' }
              }}
            >
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="body2">
                  {t('products.form.variantPreview', 'This will create')}
                </Typography>
                <Typography variant="h6" color="primary.main" fontWeight={600}>
                  {totalVariants} {t('products.form.variants', 'variants')}
                </Typography>
              </Box>
              {totalVariants > 0 && (
                <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>
                  {options.map(o => `${o.values.length} ${o.name || 'option'}`).join(' × ')}
                </Typography>
              )}
            </Alert>
          </>
        )}

        {/* Maximum options warning */}
        {options.length >= maxOptions && (
          <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
            {t('products.form.maxOptionsReached', `Maximum of ${maxOptions} options allowed`, { max: maxOptions })}
          </Typography>
        )}
      </CardContent>
    </Card>
  );
};

export default VariationOptionsEditor;
