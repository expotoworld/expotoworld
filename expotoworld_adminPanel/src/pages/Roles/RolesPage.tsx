import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  IconButton,
  Tooltip,
  Typography,
  Chip,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  AdminPanelSettings as AdminIcon,
  SupervisorAccount as ModeratorIcon,
  Person as UserIcon,
  Add as AddIcon,
  Upload as UploadIcon,
} from '@mui/icons-material';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, FilterDropdown, type Column } from '@components/common';

interface Role {
  id: string;
  name: string;
  description: string;
  usersCount: number;
  permissionsCount: number;
  isSystem: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// TODO: DUMMY DATA - Replace with actual API calls
const mockRoles: Role[] = [
  {
    id: '1',
    name: 'Super Admin',
    description: 'Full system access with all permissions',
    usersCount: 2,
    permissionsCount: 48,
    isSystem: true,
    isActive: true,
    createdAt: '2023-01-01T00:00:00Z',
    updatedAt: '2024-01-15T14:30:00Z',
  },
  {
    id: '2',
    name: 'Store Manager',
    description: 'Manage products, orders, and store settings',
    usersCount: 12,
    permissionsCount: 24,
    isSystem: false,
    isActive: true,
    createdAt: '2023-06-15T10:00:00Z',
    updatedAt: '2024-01-14T11:20:00Z',
  },
  {
    id: '3',
    name: 'Content Editor',
    description: 'Manage content and media assets',
    usersCount: 5,
    permissionsCount: 12,
    isSystem: false,
    isActive: true,
    createdAt: '2023-07-20T09:00:00Z',
    updatedAt: '2024-01-15T09:45:00Z',
  },
  {
    id: '4',
    name: 'Viewer',
    description: 'Read-only access to reports and analytics',
    usersCount: 8,
    permissionsCount: 6,
    isSystem: false,
    isActive: true,
    createdAt: '2023-08-10T15:00:00Z',
    updatedAt: '2024-01-10T13:15:00Z',
  },
  {
    id: '5',
    name: 'Customer Support',
    description: 'Handle customer inquiries and order issues',
    usersCount: 15,
    permissionsCount: 18,
    isSystem: false,
    isActive: true,
    createdAt: '2023-09-05T08:30:00Z',
    updatedAt: '2024-01-12T16:00:00Z',
  },
  {
    id: '6',
    name: 'Deprecated Role',
    description: 'Old role no longer in use',
    usersCount: 0,
    permissionsCount: 10,
    isSystem: false,
    isActive: false,
    createdAt: '2023-03-01T00:00:00Z',
    updatedAt: '2023-12-01T00:00:00Z',
  },
];

const RolesPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedRole, setSelectedRole] = useState<Role | null>(null);

  const getRoleIcon = (name: string) => {
    if (name.toLowerCase().includes('admin')) return <AdminIcon />;
    if (name.toLowerCase().includes('manager') || name.toLowerCase().includes('supervisor')) return <ModeratorIcon />;
    return <UserIcon />;
  };

  const getRoleColor = (name: string): string => {
    if (name.toLowerCase().includes('admin')) return '#EE3432';
    if (name.toLowerCase().includes('manager')) return '#0066CC';
    if (name.toLowerCase().includes('editor')) return '#107C10';
    return '#6B7280';
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const columns: Column<Role>[] = [
    {
      id: 'name',
      label: t('roles.roleName') || 'Role Name',
      minWidth: 250,
      format: (_, row) => {
        const color = getRoleColor(row.name);
        return (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: 2,
                bgcolor: `${color}20`,
                color: color,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {getRoleIcon(row.name)}
            </Box>
            <Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography variant="body2" fontWeight={500}>
                  {row.name}
                </Typography>
                {row.isSystem && (
                  <Chip label="System" size="small" color="info" sx={{ fontSize: '0.65rem' }} />
                )}
              </Box>
              <Typography variant="caption" color="text.secondary">
                {row.description}
              </Typography>
            </Box>
          </Box>
        );
      },
    },
    {
      id: 'usersCount',
      label: t('roles.users'),
      minWidth: 100,
      align: 'center',
      format: (value) => (
        <Chip label={value} size="small" variant="outlined" />
      ),
    },
    {
      id: 'permissionsCount',
      label: t('roles.permissions') || 'Permissions',
      minWidth: 120,
      align: 'center',
      format: (value) => value,
    },
    {
      id: 'isActive',
      label: t('common.status'),
      minWidth: 100,
      format: (value) => (
        <Chip
          label={value ? t('common.active') : t('common.inactive')}
          size="small"
          color={value ? 'success' : 'default'}
        />
      ),
    },
    {
      id: 'updatedAt',
      label: t('common.date'),
      minWidth: 120,
      format: (value) => formatDate(value),
    },
    {
      id: 'actions',
      label: t('common.actions'),
      minWidth: 120,
      format: (_, row) => (
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Tooltip title={t('common.view')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                navigate(`/roles/${row.id}`);
              }}
            >
              <ViewIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('common.edit')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                navigate(`/roles/${row.id}/edit`);
              }}
              disabled={row.isSystem}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title={row.isSystem ? 'System roles cannot be deleted' : t('common.delete')}>
            <span>
              <IconButton
                size="small"
                color="error"
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedRole(row);
                  setDeleteDialogOpen(true);
                }}
                disabled={row.isSystem}
              >
                <DeleteIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
        </Box>
      ),
    },
  ];

  // Filter roles
  const filteredRoles = mockRoles.filter((role) => {
    const matchesSearch =
      role.name.toLowerCase().includes(search.toLowerCase()) ||
      role.description.toLowerCase().includes(search.toLowerCase());
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && role.isActive) ||
      (statusFilter === 'inactive' && !role.isActive);
    return matchesSearch && matchesStatus;
  });

  const handleDeleteConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call delete API
    // TODO: Implement delete role API call for role: ${selectedRole?.id}
    setDeleteDialogOpen(false);
    setSelectedRole(null);
  };

  const actionMenuItems = [
    {
      label: t('roles.create'),
      icon: <AddIcon />,
      onClick: () => navigate('/roles/new'),
    },
    {
      label: t('roles.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('roles.title')} actions={<ActionMenu actions={actionMenuItems} />} />

      {/* Filters */}
      <Card elevation={0} sx={{ mb: 3 }}>
        <CardContent>
          <Box
            sx={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: 2,
              alignItems: 'center',
            }}
          >
            <TextField
              placeholder={t('roles.searchPlaceholder') || 'Search roles...'}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              size="small"
              sx={{ minWidth: 280 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon color="action" />
                  </InputAdornment>
                ),
              }}
            />
            <FilterDropdown
              label={t('common.status')}
              value={statusFilter}
              options={[
                { value: 'all', label: t('common.all') },
                { value: 'active', label: t('common.active') },
                { value: 'inactive', label: t('common.inactive') },
              ]}
              onChange={(value) => setStatusFilter(value)}
              minWidth={180}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Roles Table */}
      <DataTable
        columns={columns}
        data={filteredRoles}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredRoles.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('roles.noRoles') || 'No roles found'}
        onRowClick={(row) => navigate(`/roles/${row.id}`)}
        selectable
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('roles.deleteTitle') || 'Delete Role'}
        message={t('roles.deleteMessage', { name: selectedRole?.name }) || `Are you sure you want to delete "${selectedRole?.name}"?`}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedRole(null);
        }}
      />

    </Box>
  );
};

export default RolesPage;
