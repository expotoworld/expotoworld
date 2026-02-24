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
  Delete as DeleteIcon,
  MarkEmailRead as MarkReadIcon,
  NotificationsActive as NotificationActiveIcon,
  NotificationsOff as NotificationMutedIcon,
  ShoppingCart as OrderIcon,
  Person as UserIcon,
  Inventory as ProductIcon,
  Campaign as PromotionIcon,
  Warning as AlertIcon,
  Info as InfoIcon,
  Add as AddIcon,
  Upload as UploadIcon,
} from '@mui/icons-material';
import { DataTable, ConfirmDialog, ActionMenu, PageTitle, FilterDropdown, type Column } from '@components/common';

interface Notification {
  id: string;
  title: string;
  message: string;
  type: 'order' | 'user' | 'product' | 'promotion' | 'alert' | 'info';
  isRead: boolean;
  isMuted: boolean;
  createdAt: string;
  relatedId?: string;
}

// TODO: DUMMY DATA - Replace with actual API calls
const mockNotifications: Notification[] = [
  {
    id: 'notif-1',
    title: 'New Order Received',
    message: 'Order #ORD-2024-001 has been placed by John Doe for $125.99',
    type: 'order',
    isRead: false,
    isMuted: false,
    createdAt: '2024-01-15T10:30:00Z',
    relatedId: 'ORD-2024-001',
  },
  {
    id: 'notif-2',
    title: 'New User Registration',
    message: 'A new user "jane_smith" has registered on the platform',
    type: 'user',
    isRead: false,
    isMuted: false,
    createdAt: '2024-01-15T09:15:00Z',
    relatedId: 'user-123',
  },
  {
    id: 'notif-3',
    title: 'Low Stock Alert',
    message: 'Product "Smart Watch Pro" has only 5 units left in stock',
    type: 'product',
    isRead: true,
    isMuted: false,
    createdAt: '2024-01-14T16:45:00Z',
    relatedId: 'prod-456',
  },
  {
    id: 'notif-4',
    title: 'Promotion Ending Soon',
    message: 'Summer Sale 2024 promotion will end in 3 days',
    type: 'promotion',
    isRead: true,
    isMuted: true,
    createdAt: '2024-01-14T14:20:00Z',
    relatedId: 'promo-789',
  },
  {
    id: 'notif-5',
    title: 'System Maintenance Scheduled',
    message: 'The system will undergo maintenance on January 20, 2024 from 2:00 AM to 4:00 AM',
    type: 'alert',
    isRead: false,
    isMuted: false,
    createdAt: '2024-01-14T11:00:00Z',
  },
  {
    id: 'notif-6',
    title: 'Weekly Report Available',
    message: 'Your weekly performance report is now ready to view',
    type: 'info',
    isRead: true,
    isMuted: false,
    createdAt: '2024-01-13T08:00:00Z',
  },
  {
    id: 'notif-7',
    title: 'Order Shipped',
    message: 'Order #ORD-2024-003 has been shipped to Bob Wilson',
    type: 'order',
    isRead: true,
    isMuted: false,
    createdAt: '2024-01-13T15:30:00Z',
    relatedId: 'ORD-2024-003',
  },
  {
    id: 'notif-8',
    title: 'Payment Failed',
    message: 'Payment for order #ORD-2024-010 has failed. Please contact the customer.',
    type: 'alert',
    isRead: false,
    isMuted: false,
    createdAt: '2024-01-12T10:15:00Z',
    relatedId: 'ORD-2024-010',
  },
];

const NotificationsPage: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [_selectedNotification, setSelectedNotification] = useState<Notification | null>(null);

  const formatDate = (dateString: string) => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(new Date(dateString));
  };

  const getTypeIcon = (type: Notification['type']) => {
    const iconMap = {
      order: <OrderIcon fontSize="small" />,
      user: <UserIcon fontSize="small" />,
      product: <ProductIcon fontSize="small" />,
      promotion: <PromotionIcon fontSize="small" />,
      alert: <AlertIcon fontSize="small" />,
      info: <InfoIcon fontSize="small" />,
    };
    return iconMap[type];
  };

  const getTypeColor = (type: Notification['type']) => {
    const colorMap: Record<Notification['type'], 'primary' | 'success' | 'warning' | 'error' | 'info' | 'secondary'> = {
      order: 'primary',
      user: 'success',
      product: 'warning',
      promotion: 'secondary',
      alert: 'error',
      info: 'info',
    };
    return colorMap[type];
  };

  const columns: Column<Notification>[] = [
    {
      id: 'status',
      label: '',
      minWidth: 40,
      align: 'center',
      format: (_, row) => (
        <Avatar
          sx={{
            width: 32,
            height: 32,
            bgcolor: `${getTypeColor(row.type)}.light`,
            color: `${getTypeColor(row.type)}.main`,
          }}
        >
          {getTypeIcon(row.type)}
        </Avatar>
      ),
    },
    {
      id: 'title',
      label: t('notifications.notification'),
      minWidth: 300,
      format: (_, row) => (
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography
              variant="body2"
              sx={{
                fontWeight: row.isRead ? 400 : 600,
                color: row.isRead ? 'text.secondary' : 'text.primary',
              }}
            >
              {row.title}
            </Typography>
            {!row.isRead && (
              <Box
                sx={{
                  width: 8,
                  height: 8,
                  borderRadius: '50%',
                  bgcolor: 'primary.main',
                }}
              />
            )}
          </Box>
          <Typography
            variant="caption"
            color="text.secondary"
            sx={{
              display: 'block',
              maxWidth: 400,
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
          >
            {row.message}
          </Typography>
        </Box>
      ),
    },
    {
      id: 'type',
      label: t('notifications.type'),
      minWidth: 120,
      format: (value) => (
        <Chip
          label={t(`notifications.types.${value}`)}
          size="small"
          color={getTypeColor(value as Notification['type'])}
          variant="outlined"
        />
      ),
    },
    {
      id: 'createdAt',
      label: t('notifications.date'),
      minWidth: 150,
      format: (value) => formatDate(value),
    },
    {
      id: 'actions',
      label: t('common.actions'),
      minWidth: 120,
      format: (_, row) => (
        <Box sx={{ display: 'flex', gap: 0.5 }}>
          <Tooltip title={row.isRead ? t('notifications.markUnread') : t('notifications.markRead')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                // TODO: NEED TO FULLY IMPLEMENT - Toggle read status
              }}
            >
              <MarkReadIcon fontSize="small" color={row.isRead ? 'action' : 'primary'} />
            </IconButton>
          </Tooltip>
          <Tooltip title={row.isMuted ? t('notifications.unmute') : t('notifications.mute')}>
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                // TODO: NEED TO FULLY IMPLEMENT - Toggle mute status
              }}
            >
              {row.isMuted ? (
                <NotificationMutedIcon fontSize="small" color="action" />
              ) : (
                <NotificationActiveIcon fontSize="small" color="action" />
              )}
            </IconButton>
          </Tooltip>
          <Tooltip title={t('common.delete')}>
            <IconButton
              size="small"
              color="error"
              onClick={(e) => {
                e.stopPropagation();
                setSelectedNotification(row);
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

  // Filter notifications
  const filteredNotifications = mockNotifications.filter((notification) => {
    const matchesSearch =
      notification.title.toLowerCase().includes(search.toLowerCase()) ||
      notification.message.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || notification.type === typeFilter;
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'read' && notification.isRead) ||
      (statusFilter === 'unread' && !notification.isRead);
    return matchesSearch && matchesType && matchesStatus;
  });

  const handleDeleteConfirm = () => {
    // TODO: NEED TO FULLY IMPLEMENT - Call delete API
    // TODO: Implement delete notification API call for notification: ${_selectedNotification?.id}
    setDeleteDialogOpen(false);
    setSelectedNotification(null);
  };

  const actionMenuItems = [
    {
      label: t('notifications.create'),
      icon: <AddIcon />,
      onClick: () => navigate('/notifications/new'),
    },
    {
      label: t('notifications.upload'),
      icon: <UploadIcon />,
      onClick: () => {
        // TODO: NEED TO FULLY IMPLEMENT - Upload from file
      },
    },
  ];

  return (
    <Box>
      {/* Page Title */}
      <PageTitle title={t('notifications.title')} actions={<ActionMenu actions={actionMenuItems} />} />

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
              placeholder={t('notifications.searchPlaceholder') || 'Search notifications...'}
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
              label={t('notifications.type')}
              value={typeFilter}
              options={[
                { value: 'all', label: t('common.all') },
                { value: 'order', label: t('notifications.types.order') },
                { value: 'user', label: t('notifications.types.user') },
                { value: 'product', label: t('notifications.types.product') },
                { value: 'promotion', label: t('notifications.types.promotion') },
                { value: 'alert', label: t('notifications.types.alert') },
                { value: 'info', label: t('notifications.types.info') },
              ]}
              onChange={(value) => setTypeFilter(value)}
              minWidth={180}
            />
            <FilterDropdown
              label={t('common.status')}
              value={statusFilter}
              options={[
                { value: 'all', label: t('common.all') },
                { value: 'read', label: t('notifications.read') },
                { value: 'unread', label: t('notifications.unread') },
              ]}
              onChange={(value) => setStatusFilter(value)}
              minWidth={180}
            />
          </Box>
        </CardContent>
      </Card>

      {/* Notifications Table */}
      <DataTable
        columns={columns}
        data={filteredNotifications}
        page={page}
        rowsPerPage={rowsPerPage}
        totalCount={filteredNotifications.length}
        onPageChange={(_, newPage) => setPage(newPage)}
        onRowsPerPageChange={(e) => {
          setRowsPerPage(parseInt(e.target.value, 10));
          setPage(0);
        }}
        rowKey="id"
        emptyMessage={t('notifications.noNotifications')}
        selectable
      />

      {/* Delete Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title={t('notifications.deleteTitle')}
        message={t('notifications.deleteMessage')}
        confirmText={t('common.delete')}
        confirmColor="error"
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteDialogOpen(false);
          setSelectedNotification(null);
        }}
      />
    </Box>
  );
};

export default NotificationsPage;
