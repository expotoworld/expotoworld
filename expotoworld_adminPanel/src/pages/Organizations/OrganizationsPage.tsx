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
  Avatar,
} from '@mui/material';
import {
  Search as SearchIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Business as BusinessIcon,
  Add as AddIcon,
  Upload as UploadIcon,
} from '@mui/icons-material';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, FilterDropdown, type Column } from '@components/common';
import type { OrganizationType } from '@/types';

interface Organization {
  id: string;
  name: string;
  type: OrganizationType;
  contactPerson: string;
  contactEmail: string;
  contactPhone?: string;
  productCount: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// TODO: DUMMY DATA - Replace with actual API calls
const mockOrganizations: Organization[] = [
  {
    id: '1',
    name: 'TechCorp Industries',
    type: 'manufacturer',
    contactPerson: 'John Smith',
    contactEmail: 'john.smith@techcorp.com',
    contactPhone: '+1 234 567 8900',
    productCount: 150,
    isActive: true,
    createdAt: '2023-06-15T10:00:00Z',
    updatedAt: '2024-01-15T14:30:00Z',
  },
  {
    id: '2',
    name: 'FastShip Logistics',
    type: 'logistics',
    contactPerson: 'Jane Doe',
    contactEmail: 'jane.doe@fastship.com',
    contactPhone: '+1 234 567 8901',
    productCount: 0,
    isActive: true,
    createdAt: '2023-07-20T09:00:00Z',
    updatedAt: '2024-01-14T11:20:00Z',
  },
  {
    id: '3',
    name: 'Global Suppliers Ltd',
    type: 'supplier',
    contactPerson: 'Bob Wilson',
    contactEmail: 'bob.wilson@globalsuppliers.com',
    productCount: 280,
    isActive: true,
    createdAt: '2023-08-10T15:00:00Z',
    updatedAt: '2024-01-15T09:45:00Z',
  },
  {
    id: '4',
    name: 'Partner Solutions',
    type: 'partner',
    contactPerson: 'Alice Brown',
    contactEmail: 'alice.brown@partnersolutions.com',
    contactPhone: '+1 234 567 8902',
    productCount: 0,
    isActive: false,
    createdAt: '2023-09-05T08:30:00Z',
    updatedAt: '2024-01-10T13:15:00Z',
  },
  {
    id: '5',
    name: 'Premium Manufacturing Co',
    type: 'manufacturer',
    contactPerson: 'Charlie Davis',
    contactEmail: 'charlie.davis@premiumco.com',
    productCount: 95,
    isActive: true,
    createdAt: '2023-10-12T11:00:00Z',
    updatedAt: '2024-01-12T16:00:00Z',
  },
];

const OrganizationsPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedOrg, setSelectedOrg] = useState<Organization | null>(null);

  const getTypeColor = (type: OrganizationType): 'primary' | 'secondary' | 'info' | 'warning' => {
    const colors: Record<OrganizationType, 'primary' | 'secondary' | 'info' | 'warning'> = {
      manufacturer: 'primary',
      logistics: 'secondary',
      supplier: 'info',
      partner: 'warning',
    };
    return colors[type];
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const columns: Column<Organization>[] = [
    {
      id: 'name',
      label: t('organizations.orgName'),
      minWidth: 250,
      format: (_, row) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar sx={{ width: 48, height: 48, bgcolor: 'action.hover' }}>
            <BusinessIcon color="action" />
          </Avatar>
          <Box>
            <Typography variant="body2" fontWeight={500}>
              {row.name}
            </Typography>
            <Chip
              label={t(`organizations.types.${row.type}`)}
              size="small"
              color={getTypeColor(row.type)}
              variant="outlined"
              sx={{ mt: 0.5 }}
            />
          </Box>
        </Box>
      ),
    },
    {
      id: 'contactPerson',
      label: t('organizations.contactPerson'),
      minWidth: 150,
    },
    {
      id: 'contactEmail',
      label: t('organizations.contactEmail'),
      minWidth: 200,
      format: (value) => (
        <Typography variant="body2" color="text.secondary">
          {value}
        </Typography>
      ),
    },
    {
      id: 'productCount',
      label: t('organizations.assignedProducts'),
      minWidth: 120,
      align: 'center',
      format: (value) => (
        value > 0 ? (
          <Chip label={value} size="small" variant="outlined" />
        ) : (
          <Typography variant="body2" color="text.secondary">-</Typography>
        )
      ),
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
                navigate(`/organizations/${row.id}`);
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
                navigate(`/organizations/${row.id}/edit`);
              }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title={t('common.delete')}>
            <IconButton
              size="small"
              color="error"
              onClick={(e) => {
                e.stopPropagation();
                setSelectedOrg(row);
                setDeleteDialogOpen(true);
              }}
            >
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      ),
    },
  ];

  // Filter organizations
  const filteredOrgs = mockOrganizations.filter((org) => {
    const matchesSearch =
      org.name.toLowerCase().includes(search.toLowerCase()) ||
      org.contactPerson.toLowerCase().includes(search.toLowerCase()) ||
      org.contactEmail.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || org.type === typeFilter;
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && org.isActive) ||
      (statusFilter === 'inactive' && !org.isActive);
    return matchesSearch && matchesType && matchesStatus;
  });

  const handleDeleteConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call delete API
    // TODO: Implement delete organization API call for org: ${selectedOrg?.id}
    setDeleteDialogOpen(false);
    setSelectedOrg(null);
  };

  const actionMenuItems = [
    {
      label: t('organizations.create'),
      icon: <AddIcon />,
      onClick: () => navigate('/organizations/new'),
    },
    {
      label: t('organizations.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('organizations.title')} actions={<ActionMenu actions={actionMenuItems} />} />

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
              placeholder={t('organizations.searchPlaceholder') || 'Search organizations...'}
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
              label={t('organizations.orgType')}
              value={typeFilter}
              options={[
                { value: 'all', label: t('common.all') },
                { value: 'manufacturer', label: t('organizations.types.manufacturer') },
                { value: 'logistics', label: t('organizations.types.logistics') },
                { value: 'supplier', label: t('organizations.types.supplier') },
                { value: 'partner', label: t('organizations.types.partner') },
              ]}
              onChange={(value) => setTypeFilter(value)}
              minWidth={180}
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

      {/* Organizations Table */}
      <DataTable
        columns={columns}
        data={filteredOrgs}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredOrgs.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('organizations.noOrganizations') || 'No organizations found'}
        onRowClick={(row) => navigate(`/organizations/${row.id}`)}
        selectable
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('organizations.deleteTitle') || 'Delete Organization'}
        message={t('organizations.deleteMessage', { name: selectedOrg?.name }) || `Are you sure you want to delete "${selectedOrg?.name}"?`}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedOrg(null);
        }}
      />

    </Box>
  );
};

export default OrganizationsPage;
