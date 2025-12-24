import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  ToggleButton,
  ToggleButtonGroup,
} from '@mui/material';
import {
  ShoppingCart as OrdersIcon,
  AttachMoney as RevenueIcon,
  People as UsersIcon,
  Inventory as ProductsIcon,
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { StatCard } from '@components/common';

// TODO: NEED TO FULLY IMPLEMENT - This is a placeholder page

// TODO: DUMMY DATA - Replace with actual API calls
const revenueData = [
  { month: 'Jan', revenue: 45000, orders: 320 },
  { month: 'Feb', revenue: 52000, orders: 380 },
  { month: 'Mar', revenue: 48000, orders: 350 },
  { month: 'Apr', revenue: 61000, orders: 420 },
  { month: 'May', revenue: 55000, orders: 390 },
  { month: 'Jun', revenue: 67000, orders: 470 },
  { month: 'Jul', revenue: 72000, orders: 510 },
  { month: 'Aug', revenue: 69000, orders: 490 },
  { month: 'Sep', revenue: 78000, orders: 550 },
  { month: 'Oct', revenue: 82000, orders: 580 },
  { month: 'Nov', revenue: 91000, orders: 640 },
  { month: 'Dec', revenue: 98000, orders: 700 },
];

const storeTypeRevenue = [
  { name: 'MEGA', value: 420000, color: '#1976D2' },
  { name: 'MARKET', value: 280000, color: '#388E3C' },
  { name: 'toGO', value: 150000, color: '#7B1FA2' },
  { name: 'XPRESS', value: 90000, color: '#F57C00' },
];

const topProductsData = [
  { name: 'Wireless Headphones', sales: 1250, revenue: 124750 },
  { name: 'Smart Watch Pro', sales: 980, revenue: 244902 },
  { name: 'Organic Coffee', sales: 2100, revenue: 63000 },
  { name: 'Water Bottle', sales: 1800, revenue: 35982 },
  { name: 'Bluetooth Speaker', sales: 1450, revenue: 72485 },
];

const userGrowthData = [
  { month: 'Jan', newUsers: 120, activeUsers: 850 },
  { month: 'Feb', newUsers: 145, activeUsers: 920 },
  { month: 'Mar', newUsers: 132, activeUsers: 980 },
  { month: 'Apr', newUsers: 178, activeUsers: 1050 },
  { month: 'May', newUsers: 165, activeUsers: 1120 },
  { month: 'Jun', newUsers: 198, activeUsers: 1200 },
];

const orderStatusData = [
  { status: 'Completed', count: 4520, color: '#4CAF50' },
  { status: 'Processing', count: 320, color: '#2196F3' },
  { status: 'Pending', count: 180, color: '#FF9800' },
  { status: 'Cancelled', count: 85, color: '#F44336' },
];

const ReportsPage: React.FC = () => {
  const { t } = useTranslation();
  const [dateRange, setDateRange] = React.useState('year');
  const [selectedStore, setSelectedStore] = React.useState('all');

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
    }).format(value);
  };

  return (
    <Box>
      {/* Filters */}
      <Card elevation={0} sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
            <ToggleButtonGroup
              value={dateRange}
              exclusive
              onChange={(_, value) => value && setDateRange(value)}
              size="small"
            >
              <ToggleButton value="week">{t('reports.week')}</ToggleButton>
              <ToggleButton value="month">{t('reports.month')}</ToggleButton>
              <ToggleButton value="quarter">{t('reports.quarter')}</ToggleButton>
              <ToggleButton value="year">{t('reports.year')}</ToggleButton>
            </ToggleButtonGroup>

            <FormControl size="small" sx={{ minWidth: 180 }}>
              <InputLabel>{t('reports.store')}</InputLabel>
              <Select
                value={selectedStore}
                label={t('reports.store')}
                onChange={(e) => setSelectedStore(e.target.value)}
              >
                <MenuItem value="all">{t('reports.allStores')}</MenuItem>
                <MenuItem value="mega">MEGA Stores</MenuItem>
                <MenuItem value="market">MARKET Stores</MenuItem>
                <MenuItem value="toGo">toGO Stores</MenuItem>
                <MenuItem value="xpress">XPRESS Stores</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </CardContent>
      </Card>

      {/* KPI Stats */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title={t('reports.totalRevenue')}
            value={formatCurrency(940000)}
            change={12.5}
            changeLabel="+12.5%"
            icon={<RevenueIcon />}
            color="primary"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title={t('reports.totalOrders')}
            value="5,105"
            change={8.2}
            changeLabel="+8.2%"
            icon={<OrdersIcon />}
            color="success"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title={t('reports.activeUsers')}
            value="1,200"
            change={15.3}
            changeLabel="+15.3%"
            icon={<UsersIcon />}
            color="info"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title={t('reports.avgOrderValue')}
            value={formatCurrency(184.12)}
            change={3.8}
            changeLabel="+3.8%"
            icon={<ProductsIcon />}
            color="warning"
          />
        </Grid>
      </Grid>

      {/* Revenue Chart */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} lg={8}>
          <Card elevation={0}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('reports.revenueOverTime')}
              </Typography>
              <Box sx={{ height: 350 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={revenueData}>
                    <defs>
                      <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#1976D2" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#1976D2" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E0E0E0" />
                    <XAxis dataKey="month" />
                    <YAxis tickFormatter={(value) => `$${value / 1000}k`} />
                    <Tooltip
                      formatter={(value: number) => [formatCurrency(value), 'Revenue']}
                    />
                    <Area
                      type="monotone"
                      dataKey="revenue"
                      stroke="#1976D2"
                      fillOpacity={1}
                      fill="url(#colorRevenue)"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} lg={4}>
          <Card elevation={0} sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('reports.revenueByStoreType')}
              </Typography>
              <Box sx={{ height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={storeTypeRevenue}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={100}
                      paddingAngle={4}
                      dataKey="value"
                    >
                      {storeTypeRevenue.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip formatter={(value: number) => formatCurrency(value)} />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Orders & User Growth */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={6}>
          <Card elevation={0}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('reports.ordersByStatus')}
              </Typography>
              <Box sx={{ height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={orderStatusData} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" stroke="#E0E0E0" />
                    <XAxis type="number" />
                    <YAxis dataKey="status" type="category" width={100} />
                    <Tooltip />
                    <Bar dataKey="count" radius={[0, 4, 4, 0]}>
                      {orderStatusData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card elevation={0}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                {t('reports.userGrowth')}
              </Typography>
              <Box sx={{ height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={userGrowthData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E0E0E0" />
                    <XAxis dataKey="month" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line
                      type="monotone"
                      dataKey="newUsers"
                      stroke="#4CAF50"
                      name={t('reports.newUsers')}
                      strokeWidth={2}
                    />
                    <Line
                      type="monotone"
                      dataKey="activeUsers"
                      stroke="#2196F3"
                      name={t('reports.activeUsers')}
                      strokeWidth={2}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Top Products */}
      <Card elevation={0}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            {t('reports.topProducts')}
          </Typography>
          <Box sx={{ height: 300 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={topProductsData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E0E0E0" />
                <XAxis dataKey="name" tick={{ fontSize: 12 }} interval={0} />
                <YAxis yAxisId="left" orientation="left" stroke="#1976D2" />
                <YAxis yAxisId="right" orientation="right" stroke="#4CAF50" />
                <Tooltip
                  formatter={(value: number, name: string) => [
                    name === 'revenue' ? formatCurrency(value) : value,
                    name === 'revenue' ? 'Revenue' : 'Sales',
                  ]}
                />
                <Legend />
                <Bar
                  yAxisId="left"
                  dataKey="sales"
                  fill="#1976D2"
                  name={t('reports.sales')}
                  radius={[4, 4, 0, 0]}
                />
                <Bar
                  yAxisId="right"
                  dataKey="revenue"
                  fill="#4CAF50"
                  name={t('reports.revenue')}
                  radius={[4, 4, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default ReportsPage;
