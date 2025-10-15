import React, { useState, useEffect } from 'react';
import {
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Box,
  OutlinedInput,
  CircularProgress,
  Alert,
} from '@mui/material';
import { categoryService } from '../services/api';

const ITEM_HEIGHT = 48;
const ITEM_PADDING_TOP = 8;
const MenuProps = {
  PaperProps: {
    style: {
      maxHeight: ITEM_HEIGHT * 4.5 + ITEM_PADDING_TOP,
      width: 250,
    },
  },
};

const CategorySelector = ({ 
  selectedCategories = [], 
  onCategoriesChange, 
  disabled = false,
  multiple = true,
  label = "Categories"
}) => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        setLoading(true);
        setError(null);
        
        // For now, use mock categories since the backend might not have categories yet
        const mockCategories = [
          { id: 1, name: 'Electronics', description: 'Electronic devices and accessories' },
          { id: 2, name: 'Clothing', description: 'Apparel and fashion items' },
          { id: 3, name: 'Home & Garden', description: 'Home improvement and garden supplies' },
          { id: 4, name: 'Sports & Outdoors', description: 'Sports equipment and outdoor gear' },
          { id: 5, name: 'Books & Media', description: 'Books, movies, and digital media' },
          { id: 6, name: 'Health & Beauty', description: 'Health and beauty products' },
          { id: 7, name: 'Toys & Games', description: 'Toys and gaming products' },
          { id: 8, name: 'Food & Beverages', description: 'Food items and beverages' },
        ];
        
        // Try to fetch from API, fall back to mock data
        try {
          const data = await categoryService.getCategories();
          setCategories(data.length > 0 ? data : mockCategories);
        } catch (apiError) {
          console.warn('Failed to fetch categories from API, using mock data:', apiError);
          setCategories(mockCategories);
        }
        
      } catch (err) {
        console.error('Error loading categories:', err);
        setError(err.message || 'Failed to load categories');
      } finally {
        setLoading(false);
      }
    };

    fetchCategories();
  }, []);

  const handleChange = (event) => {
    const value = event.target.value;
    
    if (multiple) {
      // For multiple selection, value is an array
      const selectedIds = typeof value === 'string' ? value.split(',') : value;
      onCategoriesChange(selectedIds.map(id => parseInt(id)));
    } else {
      // For single selection
      onCategoriesChange(parseInt(value));
    }
  };

  const renderValue = (selected) => {
    if (!multiple) {
      const category = categories.find(cat => cat.id === selected);
      return category ? category.name : '';
    }

    // For multiple selection
    if (selected.length === 0) {
      return <em>Select categories</em>;
    }

    return (
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
        {selected.map((categoryId) => {
          const category = categories.find(cat => cat.id === categoryId);
          return (
            <Chip
              key={categoryId}
              label={category ? category.name : `Category ${categoryId}`}
              size="small"
              sx={{ height: 24 }}
            />
          );
        })}
      </Box>
    );
  };

  if (loading) {
    return (
      <FormControl fullWidth disabled>
        <InputLabel>{label}</InputLabel>
        <OutlinedInput
          label={label}
          endAdornment={<CircularProgress size={20} />}
        />
      </FormControl>
    );
  }

  if (error) {
    return (
      <Alert severity="warning" sx={{ mb: 2 }}>
        {error}
      </Alert>
    );
  }

  return (
    <FormControl fullWidth disabled={disabled}>
      <InputLabel id="category-selector-label">{label}</InputLabel>
      <Select
        labelId="category-selector-label"
        multiple={multiple}
        value={multiple ? selectedCategories : (selectedCategories[0] || '')}
        onChange={handleChange}
        input={<OutlinedInput label={label} />}
        renderValue={renderValue}
        MenuProps={MenuProps}
      >
        {categories.map((category) => (
          <MenuItem key={category.id} value={category.id}>
            <Box>
              <Box sx={{ fontWeight: 500 }}>{category.name}</Box>
              {category.description && (
                <Box sx={{ fontSize: '0.875rem', color: 'text.secondary' }}>
                  {category.description}
                </Box>
              )}
            </Box>
          </MenuItem>
        ))}
      </Select>
    </FormControl>
  );
};

export default CategorySelector;
