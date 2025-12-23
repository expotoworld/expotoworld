import React from 'react';
import { useTranslation } from 'react-i18next';
import { Box, Typography, Button, Card, CardContent, Grid } from '@mui/material';
import { Add as AddIcon, Category as CategoryIcon } from '@mui/icons-material';
import { PageHeader } from '@components/common';

// TODO: NEED TO FULLY IMPLEMENT - This is a placeholder page

const CategoriesPage: React.FC = () => {
  const { t } = useTranslation();

  // TODO: DUMMY DATA - Replace with actual API calls
  const mockCategories = [
    { id: '1', name: 'Electronics', productCount: 150, subcategories: 12 },
    { id: '2', name: 'Food & Beverage', productCount: 280, subcategories: 18 },
    { id: '3', name: 'Home & Living', productCount: 95, subcategories: 8 },
    { id: '4', name: 'Fashion', productCount: 320, subcategories: 15 },
    { id: '5', name: 'Health & Beauty', productCount: 180, subcategories: 10 },
    { id: '6', name: 'Sports & Outdoors', productCount: 120, subcategories: 7 },
  ];

  return (
    <Box>
      <PageHeader
        title={t('categories.title')}
        subtitle={t('categories.subtitle')}
        breadcrumbs={[
          { label: t('nav.dashboard'), path: '/' },
          { label: t('nav.categories') },
        ]}
        actions={
          <Button
            variant="contained"
            startIcon={<AddIcon />}
          >
            {t('categories.addCategory')}
          </Button>
        }
      />

      <Grid container spacing={3}>
        {mockCategories.map((category) => (
          <Grid item xs={12} sm={6} md={4} key={category.id}>
            <Card
              elevation={0}
              sx={{
                cursor: 'pointer',
                transition: 'transform 0.2s',
                '&:hover': { transform: 'translateY(-4px)' },
              }}
            >
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                  <Box
                    sx={{
                      width: 48,
                      height: 48,
                      borderRadius: 2,
                      bgcolor: 'primary.main',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <CategoryIcon sx={{ color: 'white' }} />
                  </Box>
                  <Box>
                    <Typography variant="h6" fontWeight={600}>
                      {category.name}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {category.subcategories} {t('categories.subcategories')}
                    </Typography>
                  </Box>
                </Box>
                <Typography variant="body2" color="text.secondary">
                  {category.productCount} {t('products.title').toLowerCase()}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default CategoriesPage;
