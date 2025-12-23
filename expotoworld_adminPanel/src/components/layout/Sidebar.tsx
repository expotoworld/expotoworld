import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  alpha,
  useTheme,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Inventory2 as ProductsIcon,
  ShoppingCart as OrdersIcon,
  People as UsersIcon,
  Store as StoresIcon,
  Category as CategoriesIcon,
  Business as OrganizationsIcon,
  Map as RegionsIcon,
  ShoppingBasket as CartsIcon,
  Image as ContentIcon,
  Analytics as ReportsIcon,
  Settings as SettingsIcon,
} from '@mui/icons-material';
import { componentSpacing } from '@theme/spacing';

interface SidebarProps {
  open: boolean;
  onClose?: () => void;
  variant?: 'permanent' | 'temporary';
}

interface NavItem {
  id: string;
  labelKey: string;
  path: string;
  icon: React.ReactNode;
}

const navItems: NavItem[] = [
  { id: 'dashboard', labelKey: 'nav.dashboard', path: '/', icon: <DashboardIcon /> },
  { id: 'products', labelKey: 'nav.products', path: '/products', icon: <ProductsIcon /> },
  { id: 'orders', labelKey: 'nav.orders', path: '/orders', icon: <OrdersIcon /> },
  { id: 'users', labelKey: 'nav.users', path: '/users', icon: <UsersIcon /> },
  { id: 'stores', labelKey: 'nav.stores', path: '/stores', icon: <StoresIcon /> },
  { id: 'categories', labelKey: 'nav.categories', path: '/categories', icon: <CategoriesIcon /> },
  {
    id: 'organizations',
    labelKey: 'nav.organizations',
    path: '/organizations',
    icon: <OrganizationsIcon />,
  },
  { id: 'regions', labelKey: 'nav.regions', path: '/regions', icon: <RegionsIcon /> },
  { id: 'carts', labelKey: 'nav.carts', path: '/carts', icon: <CartsIcon /> },
  { id: 'content', labelKey: 'nav.content', path: '/content', icon: <ContentIcon /> },
  { id: 'reports', labelKey: 'nav.reports', path: '/reports', icon: <ReportsIcon /> },
];

const secondaryNavItems: NavItem[] = [
  { id: 'settings', labelKey: 'nav.settings', path: '/settings', icon: <SettingsIcon /> },
];

const Sidebar: React.FC<SidebarProps> = ({ open, onClose, variant = 'permanent' }) => {
  const { t } = useTranslation();
  const theme = useTheme();
  const location = useLocation();
  const navigate = useNavigate();

  const isActive = (path: string) => {
    if (path === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(path);
  };

  const handleNavigation = (path: string) => {
    navigate(path);
    if (variant === 'temporary' && onClose) {
      onClose();
    }
  };

  const drawerContent = (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        bgcolor: 'background.default',
      }}
    >
      {/* Logo Section */}
      <Box
        sx={{
          height: componentSpacing.headerHeight,
          display: 'flex',
          alignItems: 'center',
          px: 3,
        }}
      >
        <Typography
          variant="h5"
          sx={{
            fontWeight: 700,
            color: 'primary.main',
            letterSpacing: '-0.02em',
          }}
        >
          EXPO to WORLD
        </Typography>
      </Box>

      {/* Main Navigation */}
      <Box sx={{ flex: 1, overflow: 'auto', py: 2 }}>
        <List sx={{ px: 2 }}>
          {navItems.map((item) => {
            const active = isActive(item.path);
            return (
              <ListItem key={item.id} disablePadding sx={{ mb: 0.5 }}>
                <ListItemButton
                  onClick={() => handleNavigation(item.path)}
                  sx={{
                    borderRadius: 2,
                    py: 1.25,
                    px: 2,
                    bgcolor: active ? alpha(theme.palette.primary.main, 0.1) : 'transparent',
                    color: active ? 'primary.main' : 'text.secondary',
                    '&:hover': {
                      bgcolor: active
                        ? alpha(theme.palette.primary.main, 0.15)
                        : alpha(theme.palette.action.hover, 0.04),
                    },
                  }}
                >
                  <ListItemIcon
                    sx={{
                      minWidth: 40,
                      color: active ? 'primary.main' : 'text.secondary',
                    }}
                  >
                    {item.icon}
                  </ListItemIcon>
                  <ListItemText
                    primary={t(item.labelKey)}
                    primaryTypographyProps={{
                      fontWeight: active ? 600 : 500,
                      fontSize: '0.875rem',
                    }}
                  />
                </ListItemButton>
              </ListItem>
            );
          })}
        </List>
      </Box>

      {/* Secondary Navigation */}
      <Box sx={{ py: 2 }}>
        <List sx={{ px: 2 }}>
          {secondaryNavItems.map((item) => {
            const active = isActive(item.path);
            return (
              <ListItem key={item.id} disablePadding>
                <ListItemButton
                  onClick={() => handleNavigation(item.path)}
                  sx={{
                    borderRadius: 2,
                    py: 1.25,
                    px: 2,
                    bgcolor: active ? alpha(theme.palette.primary.main, 0.1) : 'transparent',
                    color: active ? 'primary.main' : 'text.secondary',
                    '&:hover': {
                      bgcolor: active
                        ? alpha(theme.palette.primary.main, 0.15)
                        : alpha(theme.palette.action.hover, 0.04),
                    },
                  }}
                >
                  <ListItemIcon
                    sx={{
                      minWidth: 40,
                      color: active ? 'primary.main' : 'text.secondary',
                    }}
                  >
                    {item.icon}
                  </ListItemIcon>
                  <ListItemText
                    primary={t(item.labelKey)}
                    primaryTypographyProps={{
                      fontWeight: active ? 600 : 500,
                      fontSize: '0.875rem',
                    }}
                  />
                </ListItemButton>
              </ListItem>
            );
          })}
        </List>
      </Box>
    </Box>
  );

  return (
    <Drawer
      variant={variant}
      open={open}
      onClose={onClose}
      sx={{
        width: componentSpacing.sidebarWidth,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: componentSpacing.sidebarWidth,
          boxSizing: 'border-box',
          borderRight: 'none',
        },
      }}
    >
      {drawerContent}
    </Drawer>
  );
};

export default Sidebar;
