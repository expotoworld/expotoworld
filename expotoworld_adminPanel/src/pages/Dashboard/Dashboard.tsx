import React from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Divider,
  Button,
  useTheme,
} from '@mui/material';
import {
  AttachMoney as RevenueIcon,
  ShoppingCart as OrdersIcon,
  People as UsersIcon,
  Inventory2 as ProductsIcon,
  Pending as PendingIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { PageHeader, StatCard, StatusChip } from '@components/common';
import type { DashboardStats, ChartDataPoint, RecentOrder, TopProduct } from '@/types';

// TODO: DUMMY DATA - Replace with actual API calls
const mockStats: DashboardStats = {
  totalRevenue: 125840.5,
  totalOrders: 1284,
  totalUsers: 8542,
  totalProducts: 3421,
  pendingOrders: 23,
  lowStockProducts: 12,
  revenueChange: 12.5,
  ordersChange: 8.3,
  usersChange: 15.2,
};

const mockRevenueData: ChartDataPoint[] = [
  { date: 'Jan', value: 65000 },
  { date: 'Feb', value: 78000 },
  { date: 'Mar', value: 85000 },
  { date: 'Apr', value: 92000 },
  { date: 'May', value: 108000 },
  { date: 'Jun', value: 125840 },
];

const mockOrdersByStatus = [
  { name: 'Pending', value: 23, color: '#F59E0B' },
  { name: 'Processing', value: 45, color: '#3B82F6' },
  { name: 'Shipped', value: 128, color: '#8B5CF6' },
  { name: 'Delivered', value: 1088, color: '#10B981' },
];

const mockRecentOrders: RecentOrder[] = [
  { id: 'ORD-2024-001', customerName: 'John Doe', total: 125.99, status: 'pending', createdAt: '2024-01-15T10:30:00Z' },
  { id: 'ORD-2024-002', customerName: 'Jane Smith', total: 89.5, status: 'processing', createdAt: '2024-01-15T09:15:00Z' },
  { id: 'ORD-2024-003', customerName: 'Bob Wilson', total: 256.0, status: 'shipped', createdAt: '2024-01-14T16:45:00Z' },
  { id: 'ORD-2024-004', customerName: 'Alice Brown', total: 45.99, status: 'delivered', createdAt: '2024-01-14T14:20:00Z' },
  { id: 'ORD-2024-005', customerName: 'Charlie Davis', total: 178.25, status: 'completed', createdAt: '2024-01-14T11:00:00Z' },
];

const mockTopProducts: TopProduct[] = [
  { id: '1', name: 'Premium Wireless Headphones', sales: 245, revenue: 24500, imageUrl: '' },
  { id: '2', name: 'Organic Coffee Beans 1kg', sales: 189, revenue: 5670, imageUrl: '' },
  { id: '3', name: 'Smart Watch Pro', sales: 156, revenue: 39000, imageUrl: '' },
  { id: '4', name: 'Eco-Friendly Water Bottle', sales: 142, revenue: 2840, imageUrl: '' },
  { id: '5', name: 'Bluetooth Speaker Mini', sales: 128, revenue: 6400, imageUrl: '' },
];

const Dashboard: React.FC = () => {
  const { t } = useTranslation();
  const theme = useTheme();
  const navigate = useNavigate();

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  return (
    <Box>
      <PageHeader
        title={t('dashboard.title')}
        subtitle={t('dashboard.subtitle')}
      />

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title={t('dashboard.totalRevenue')}
            value={formatCurrency(mockStats.totalRevenue)}
            change={mockStats.revenueChange}
            changeLabel={t('dashboard.vsLastMonth')}
            icon={<RevenueIcon />}
            color="success"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title={t('dashboard.totalOrders')}
            value={mockStats.totalOrders.toLocaleString()}
            change={mockStats.ordersChange}
            changeLabel={t('dashboard.vsLastMonth')}
            icon={<OrdersIcon />}
            color="primary"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title={t('dashboard.totalUsers')}
            value={mockStats.totalUsers.toLocaleString()}
            change={mockStats.usersChange}
            changeLabel={t('dashboard.vsLastMonth')}
            icon={<UsersIcon />}
            color="info"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title={t('dashboard.totalProducts')}
            value={mockStats.totalProducts.toLocaleString()}
            icon={<ProductsIcon />}
            color="secondary"
          />
        </Grid>
      </Grid>

      {/* Alert Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6}>
          <Card
            elevation={0}
            sx={{
              bgcolor: theme.palette.mode === 'dark' ? 'rgba(245, 158, 11, 0.1)' : 'rgba(245, 158, 11, 0.05)',
              border: `1px solid ${theme.palette.warning.main}`,
              cursor: 'pointer',
              transition: 'transform 0.2s',
              '&:hover': { transform: 'translateY(-2px)' },
            }}
            onClick={() => navigate('/orders?status=pending')}
          >
            <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <PendingIcon sx={{ fontSize: 40, color: 'warning.main' }} />
              <Box>
                <Typography variant="h5" fontWeight={700}>
                  {mockStats.pendingOrders}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {t('dashboard.pendingOrders')}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6}>
          <Card
            elevation={0}
            sx={{
              bgcolor: theme.palette.mode === 'dark' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(239, 68, 68, 0.05)',
              border: `1px solid ${theme.palette.error.main}`,
              cursor: 'pointer',
              transition: 'transform 0.2s',
              '&:hover': { transform: 'translateY(-2px)' },
            }}
            onClick={() => navigate('/products?filter=low_stock')}
          >
            <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <WarningIcon sx={{ fontSize: 40, color: 'error.main' }} />
              <Box>
                <Typography variant="h5" fontWeight={700}>
                  {mockStats.lowStockProducts}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {t('dashboard.lowStock')}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Charts Row */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {/* Revenue Chart */}
        <Grid item xs={12} md={8}>
          <Card elevation={0}>
            <CardContent>
              <Typography variant="h6" fontWeight={600} sx={{ mb: 3 }}>
                {t('dashboard.revenueOverview')}
              </Typography>
              <Box sx={{ height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={mockRevenueData}>
                    <CartesianGrid
                      strokeDasharray="3 3"
                      stroke={theme.palette.divider}
                    />
                    <XAxis
                      dataKey="date"
                      tick={{ fill: theme.palette.text.secondary, fontSize: 12 }}
                    />
                    <YAxis
                      tick={{ fill: theme.palette.text.secondary, fontSize: 12 }}
                      tickFormatter={(value) => `$${value / 1000}k`}
                    />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: theme.palette.background.paper,
                        border: `1px solid ${theme.palette.divider}`,
                        borderRadius: 8,
                      }}
                      formatter={(value: number) => [formatCurrency(value), 'Revenue']}
                    />
                    <Line
                      type="monotone"
                      dataKey="value"
                      stroke={theme.palette.primary.main}
                      strokeWidth={2}
                      dot={{ fill: theme.palette.primary.main, strokeWidth: 2 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Orders by Status */}
        <Grid item xs={12} md={4}>
          <Card elevation={0} sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="h6" fontWeight={600} sx={{ mb: 3 }}>
                {t('dashboard.ordersByStatus')}
              </Typography>
              <Box sx={{ height: 250, display: 'flex', justifyContent: 'center' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={mockOrdersByStatus}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={80}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      {mockOrdersByStatus.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip
                      contentStyle={{
                        backgroundColor: theme.palette.background.paper,
                        border: `1px solid ${theme.palette.divider}`,
                        borderRadius: 8,
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </Box>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, justifyContent: 'center' }}>
                {mockOrdersByStatus.map((item) => (
                  <Box
                    key={item.name}
                    sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}
                  >
                    <Box
                      sx={{
                        width: 12,
                        height: 12,
                        borderRadius: '50%',
                        bgcolor: item.color,
                      }}
                    />
                    <Typography variant="caption" color="text.secondary">
                      {item.name} ({item.value})
                    </Typography>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Recent Orders and Top Products */}
      <Grid container spacing={3}>
        {/* Recent Orders */}
        <Grid item xs={12} md={6}>
          <Card elevation={0}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6" fontWeight={600}>
                  {t('dashboard.recentOrders')}
                </Typography>
                <Button
                  size="small"
                  onClick={() => navigate('/orders')}
                >
                  {t('common.viewAll')}
                </Button>
              </Box>
              <List disablePadding>
                {mockRecentOrders.map((order, index) => (
                  <React.Fragment key={order.id}>
                    <ListItem
                      sx={{ px: 0, cursor: 'pointer' }}
                      onClick={() => navigate(`/orders/${order.id}`)}
                    >
                      <ListItemText
                        primary={
                          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <Typography variant="body2" fontWeight={500}>
                              {order.id}
                            </Typography>
                            <StatusChip status={order.status} />
                          </Box>
                        }
                        secondary={
                          <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
                            <Typography variant="caption" color="text.secondary">
                              {order.customerName}
                            </Typography>
                            <Typography variant="body2" fontWeight={500}>
                              {formatCurrency(order.total)}
                            </Typography>
                          </Box>
                        }
                      />
                    </ListItem>
                    {index < mockRecentOrders.length - 1 && <Divider />}
                  </React.Fragment>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Top Products */}
        <Grid item xs={12} md={6}>
          <Card elevation={0}>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6" fontWeight={600}>
                  {t('dashboard.topProducts')}
                </Typography>
                <Button
                  size="small"
                  onClick={() => navigate('/products')}
                >
                  {t('common.viewAll')}
                </Button>
              </Box>
              <List disablePadding>
                {mockTopProducts.map((product, index) => (
                  <React.Fragment key={product.id}>
                    <ListItem
                      sx={{ px: 0, cursor: 'pointer' }}
                      onClick={() => navigate(`/products/${product.id}`)}
                    >
                      <ListItemAvatar>
                        <Avatar
                          variant="rounded"
                          sx={{ bgcolor: 'action.hover' }}
                        >
                          {index + 1}
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary={
                          <Typography variant="body2" fontWeight={500} noWrap>
                            {product.name}
                          </Typography>
                        }
                        secondary={
                          <Typography variant="caption" color="text.secondary">
                            {product.sales} {t('dashboard.sold')}
                          </Typography>
                        }
                      />
                      <Typography variant="body2" fontWeight={500}>
                        {formatCurrency(product.revenue)}
                      </Typography>
                    </ListItem>
                    {index < mockTopProducts.length - 1 && <Divider />}
                  </React.Fragment>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
