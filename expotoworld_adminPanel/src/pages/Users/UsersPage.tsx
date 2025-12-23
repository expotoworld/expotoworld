import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Button,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  Typography,
  Chip,
  Avatar,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  Edit as EditIcon,
  Visibility as ViewIcon,
  Block as BlockIcon,
  CheckCircle as ActivateIcon,
} from '@mui/icons-material';
import { PageHeader, DataTable, ConfirmDialog, type Column } from '@components/common';
import type { User, UserRole } from '@/types';

// TODO: DUMMY DATA - Replace with actual API calls
const mockUsers: User[] = [
  {
    id: 'user-1',
    username: 'johndoe',
    realName: 'John Doe',
    email: 'john.doe@example.com',
    phone: '+1 234 567 8900',
    role: 'customer',
    status: 'active',
    totalOrders: 15,
    totalSpent: 1250.50,
    walletBalance: 50.00,
    createdAt: '2024-01-01T10:00:00Z',
    lastLoginAt: '2024-01-15T09:30:00Z',
  },
  {
    id: 'user-2',
    username: 'janesmith',
    realName: 'Jane Smith',
    email: 'jane.smith@example.com',
    phone: '+1 234 567 8901',
    role: 'customer',
    status: 'active',
    totalOrders: 28,
    totalSpent: 2890.75,
    walletBalance: 125.00,
    createdAt: '2023-12-15T08:00:00Z',
    lastLoginAt: '2024-01-15T14:20:00Z',
  },
  {
    id: 'user-3',
    username: 'bobwilson',
    realName: 'Bob Wilson',
    email: 'bob.wilson@example.com',
    role: 'customer',
    status: 'suspended',
    totalOrders: 3,
    totalSpent: 150.00,
    walletBalance: 0,
    createdAt: '2024-01-05T12:00:00Z',
    lastLoginAt: '2024-01-10T11:00:00Z',
  },
  {
    id: 'user-4',
    username: 'alicebrown',
    realName: 'Alice Brown',
    email: 'alice.brown@company.com',
    phone: '+1 234 567 8902',
    role: 'manufacturer',
    status: 'active',
    totalOrders: 0,
    totalSpent: 0,
    walletBalance: 0,
    organizationId: 'org-1',
    createdAt: '2023-11-20T09:00:00Z',
    lastLoginAt: '2024-01-15T08:45:00Z',
  },
  {
    id: 'user-5',
    username: 'charliedavis',
    realName: 'Charlie Davis',
    email: 'charlie@logistics.com',
    role: 'logistics',
    status: 'active',
    totalOrders: 0,
    totalSpent: 0,
    walletBalance: 0,
    organizationId: 'org-2',
    createdAt: '2023-10-10T14:00:00Z',
    lastLoginAt: '2024-01-14T16:30:00Z',
  },
];

const UsersPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [statusDialogOpen, setStatusDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const getRoleColor = (role: UserRole): 'default' | 'primary' | 'secondary' | 'info' | 'success' | 'warning' => {
    const colors: Record<UserRole, 'default' | 'primary' | 'secondary' | 'info' | 'success' | 'warning'> = {
      admin: 'error' as 'warning',
      customer: 'default',
      manufacturer: 'primary',
      logistics: 'secondary',
      partner: 'info',
    };
    return colors[role] || 'default';
  };

  const columns: Column<User>[] = [
    {
      id: 'username',
      label: t('users.user'),
      minWidth: 200,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar
            src={row.profileImageUrl}
            sx={{ width: 40, height: 40, bgcolor: 'primary.main' }}
          >
            {row.username.charAt(0).toUpperCase()}
          </Avatar>
          <Box>
            <Typography variant="body2" fontWeight={500}>
              {row.realName || row.username}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              @{row.username}
            </Typography>
          </Box>
        </Box>
      ),
    },
    {
      id: 'email',
      label: t('users.email'),
      minWidth: 180,
    },
    {
      id: 'role',
      label: t('users.role'),
      minWidth: 120,
      format: (value) => (
        <Chip
          label={t(`users.roles.${value}`)}
          size="small"
          color={getRoleColor(value as UserRole)}
          variant="outlined"
        />
      ),
    },
    {
      id: 'status',
      label: t('common.status'),
      minWidth: 100,
      format: (value) => (
        <Chip
          label={t(`users.statuses.${value}`)}
          size="small"
          color={value === 'active' ? 'success' : value === 'suspended' ? 'error' : 'warning'}
        />
      ),
    },
    {
      id: 'totalOrders',
      label: t('users.orders'),
      minWidth: 80,
      align: 'center',
    },
    {
      id: 'totalSpent',
      label: t('users.totalSpent'),
      minWidth: 100,
      format: (value) => formatCurrency(value),
    },
    {
      id: 'createdAt',
      label: t('users.joinDate'),
      minWidth: 120,
      format: (value) => formatDate(value),
    },
    {
      id: 'actions',
      label: t('common.actions'),
      minWidth: 150,
      align: 'right',
      format: (_, row) => (
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 0.5 }}>
          <Tooltip title={t('common.view')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                navigate(`/users/${row.id}`);
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
                navigate(`/users/${row.id}/edit`);
              }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          {row.status === 'active' ? (
            <Tooltip title={t('users.suspend')}>
              <IconButton
                size="small"
                color="warning"
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedUser(row);
                  setStatusDialogOpen(true);
                }}
              >
                <BlockIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          ) : (
            <Tooltip title={t('users.activate')}>
              <IconButton
                size="small"
                color="success"
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedUser(row);
                  setStatusDialogOpen(true);
                }}
              >
                <ActivateIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
        </Box>
      ),
    },
  ];

  // Filter users
  const filteredUsers = mockUsers.filter((user) => {
    const matchesSearch = 
      user.username.toLowerCase().includes(search.toLowerCase()) ||
      user.email.toLowerCase().includes(search.toLowerCase()) ||
      (user.realName?.toLowerCase().includes(search.toLowerCase()) ?? false);
    const matchesRole = roleFilter === 'all' || user.role === roleFilter;
    const matchesStatus = statusFilter === 'all' || user.status === statusFilter;
    return matchesSearch && matchesRole && matchesStatus;
  });

  const handleStatusConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call update user status API
    console.log('Toggle status for user:', selectedUser?.id);
    setStatusDialogOpen(false);
    setSelectedUser(null);
  };

  return (
    <Box>
      <PageHeader
        title={t('users.title')}
        subtitle={t('users.subtitle')}
        breadcrumbs={[
          { label: t('nav.dashboard'), path: '/' },
          { label: t('nav.users') },
        ]}
        actions={
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => navigate('/users/new')}
          >
            {t('users.addUser')}
          </Button>
        }
      />

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
              placeholder={t('users.searchPlaceholder')}
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
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>{t('users.role')}</InputLabel>
              <Select
                value={roleFilter}
                label={t('users.role')}
                onChange={(e) => setRoleFilter(e.target.value)}
              >
                <MenuItem value="all">{t('common.all')}</MenuItem>
                <MenuItem value="customer">{t('users.roles.customer')}</MenuItem>
                <MenuItem value="manufacturer">{t('users.roles.manufacturer')}</MenuItem>
                <MenuItem value="logistics">{t('users.roles.logistics')}</MenuItem>
                <MenuItem value="partner">{t('users.roles.partner')}</MenuItem>
              </Select>
            </FormControl>
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>{t('common.status')}</InputLabel>
              <Select
                value={statusFilter}
                label={t('common.status')}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <MenuItem value="all">{t('common.all')}</MenuItem>
                <MenuItem value="active">{t('users.statuses.active')}</MenuItem>
                <MenuItem value="suspended">{t('users.statuses.suspended')}</MenuItem>
                <MenuItem value="pending">{t('users.statuses.pending')}</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </CardContent>
      </Card>

      {/* Users Table */}
      <DataTable
        columns={columns}
        data={filteredUsers}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredUsers.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('users.noUsers')}
        onRowClick={(row) => navigate(`/users/${row.id}`)}
      />

      {/* Status Change Dialog */}
      <ConfirmDialog
        open={statusDialogOpen}
        title={selectedUser?.status === 'active' ? t('users.suspendTitle') : t('users.activateTitle')}
        message={
          selectedUser?.status === 'active'
            ? t('users.suspendMessage', { name: selectedUser?.username })
            : t('users.activateMessage', { name: selectedUser?.username })
        }
        confirmText={selectedUser?.status === 'active' ? t('users.suspend') : t('users.activate')}
        confirmColor={selectedUser?.status === 'active' ? 'warning' : 'success'}
        onConfirm={handleStatusConfirm}
        onCancel={() => {
          setStatusDialogOpen(false);
          setSelectedUser(null);
        }}
      />
    </Box>
  );
};

export default UsersPage;
