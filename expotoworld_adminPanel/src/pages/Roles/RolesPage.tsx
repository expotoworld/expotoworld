import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  Button,
  Chip,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Security as SecurityIcon,
  AdminPanelSettings as AdminIcon,
  Person as UserIcon,
  SupervisorAccount as ModeratorIcon,
} from '@mui/icons-material';

// TODO: NEED TO FULLY IMPLEMENT - This is a placeholder page

// TODO: DUMMY DATA - Replace with actual API calls
const mockRoles = [
  {
    id: '1',
    name: 'Super Admin',
    description: 'Full system access with all permissions',
    usersCount: 2,
    permissions: ['all'],
    icon: <AdminIcon />,
    color: '#EE3432',
  },
  {
    id: '2',
    name: 'Store Manager',
    description: 'Manage products, orders, and store settings',
    usersCount: 12,
    permissions: ['products.read', 'products.write', 'orders.read', 'orders.write', 'stores.read'],
    icon: <ModeratorIcon />,
    color: '#0066CC',
  },
  {
    id: '3',
    name: 'Content Editor',
    description: 'Manage content and media assets',
    usersCount: 5,
    permissions: ['content.read', 'content.write', 'categories.read'],
    icon: <UserIcon />,
    color: '#107C10',
  },
  {
    id: '4',
    name: 'Viewer',
    description: 'Read-only access to reports and analytics',
    usersCount: 8,
    permissions: ['reports.read', 'analytics.read'],
    icon: <UserIcon />,
    color: '#6B7280',
  },
];

const mockPermissions = [
  { module: 'Products', permissions: ['Read', 'Write', 'Delete'] },
  { module: 'Orders', permissions: ['Read', 'Write', 'Cancel', 'Refund'] },
  { module: 'Users', permissions: ['Read', 'Write', 'Delete', 'Invite'] },
  { module: 'Stores', permissions: ['Read', 'Write', 'Delete'] },
  { module: 'Categories', permissions: ['Read', 'Write', 'Delete'] },
  { module: 'Content', permissions: ['Read', 'Write', 'Delete', 'Publish'] },
  { module: 'Reports', permissions: ['Read', 'Export'] },
  { module: 'Settings', permissions: ['Read', 'Write'] },
];

const RolesPage: React.FC = () => {
  const { t } = useTranslation();

  return (
    <Box>
      {/* Actions */}
      <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 3 }}>
        <Button variant="contained" startIcon={<AddIcon />}>
          {t('roles.addRole')}
        </Button>
      </Box>

      {/* Roles Overview */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {mockRoles.map((role) => (
          <Grid item xs={12} sm={6} md={3} key={role.id}>
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
                <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 2 }}>
                  <Box
                    sx={{
                      width: 48,
                      height: 48,
                      borderRadius: 2,
                      bgcolor: `${role.color}20`,
                      color: role.color,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    {role.icon}
                  </Box>
                  <IconButton size="small">
                    <EditIcon fontSize="small" />
                  </IconButton>
                </Box>
                <Typography variant="h6" fontWeight={600} gutterBottom>
                  {role.name}
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {role.description}
                </Typography>
                <Chip
                  label={`${role.usersCount} ${t('roles.users')}`}
                  size="small"
                  sx={{ bgcolor: 'action.hover' }}
                />
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Permissions Matrix */}
      <Card elevation={0}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
            <SecurityIcon color="primary" />
            <Typography variant="h6">{t('roles.permissionsMatrix')}</Typography>
          </Box>

          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>{t('roles.module')}</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>{t('roles.availablePermissions')}</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {mockPermissions.map((item) => (
                  <TableRow key={item.module}>
                    <TableCell>
                      <Typography variant="body2" fontWeight={500}>
                        {item.module}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                        {item.permissions.map((perm) => (
                          <Chip
                            key={perm}
                            label={perm}
                            size="small"
                            variant="outlined"
                            sx={{ fontSize: '0.75rem' }}
                          />
                        ))}
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Box>
  );
};

export default RolesPage;
