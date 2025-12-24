import React from 'react';
import { useTranslation } from 'react-i18next';
import { Box, Typography, Button, Card, CardContent, Grid, Chip, Avatar } from '@mui/material';
import { Add as AddIcon, Business as BusinessIcon } from '@mui/icons-material';
import type { OrganizationType } from '@/types';

// TODO: NEED TO FULLY IMPLEMENT - This is a placeholder page

const OrganizationsPage: React.FC = () => {
  const { t } = useTranslation();

  // TODO: DUMMY DATA - Replace with actual API calls
  const mockOrganizations = [
    { id: '1', name: 'TechCorp Industries', type: 'manufacturer' as OrganizationType, productCount: 150, contactPerson: 'John Smith', isActive: true },
    { id: '2', name: 'FastShip Logistics', type: 'logistics' as OrganizationType, productCount: 0, contactPerson: 'Jane Doe', isActive: true },
    { id: '3', name: 'Global Suppliers Ltd', type: 'supplier' as OrganizationType, productCount: 280, contactPerson: 'Bob Wilson', isActive: true },
    { id: '4', name: 'Partner Solutions', type: 'partner' as OrganizationType, productCount: 0, contactPerson: 'Alice Brown', isActive: false },
  ];

  const getTypeColor = (type: OrganizationType) => {
    const colors: Record<OrganizationType, 'primary' | 'secondary' | 'info' | 'warning'> = {
      manufacturer: 'primary',
      logistics: 'secondary',
      supplier: 'info',
      partner: 'warning',
    };
    return colors[type];
  };

  return (
    <Box>
      {/* Actions */}
      <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
        >
          {t('organizations.addOrganization')}
        </Button>
      </Box>

      <Grid container spacing={3}>
        {mockOrganizations.map((org) => (
          <Grid item xs={12} sm={6} md={4} lg={3} key={org.id}>
            <Card
              elevation={0}
              sx={{
                height: '100%',
                cursor: 'pointer',
                transition: 'transform 0.2s',
                '&:hover': { transform: 'translateY(-4px)' },
              }}
            >
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                  <Avatar sx={{ width: 48, height: 48, bgcolor: 'action.hover' }}>
                    <BusinessIcon color="action" />
                  </Avatar>
                  <Box sx={{ flex: 1, minWidth: 0 }}>
                    <Typography variant="subtitle1" fontWeight={600} noWrap>
                      {org.name}
                    </Typography>
                    <Chip
                      label={t(`organizations.types.${org.type}`)}
                      size="small"
                      color={getTypeColor(org.type)}
                      variant="outlined"
                      sx={{ mt: 0.5 }}
                    />
                  </Box>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2" color="text.secondary">
                    {org.contactPerson}
                  </Typography>
                  <Chip
                    label={org.isActive ? t('common.active') : t('common.inactive')}
                    size="small"
                    color={org.isActive ? 'success' : 'default'}
                  />
                </Box>
                {org.productCount > 0 && (
                  <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                    {org.productCount} {t('products.title').toLowerCase()}
                  </Typography>
                )}
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default OrganizationsPage;
