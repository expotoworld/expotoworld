import React, { useState, useRef, useEffect, memo } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  AppBar,
  Toolbar,
  Box,
  Typography,
  IconButton,
  Avatar,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider,
  Tooltip,
  Badge,
  useTheme,
  alpha,
  Collapse,
  List,
  ListItem,
  ListItemButton,
  Paper,
  Popper,
  Fade,
  ButtonBase,
  Theme,
  ClickAwayListener,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Close as CloseIcon,
  KeyboardArrowDown as ChevronDownIcon,
  LightMode as SunIcon,
  DarkMode as MoonIcon,
  Translate as TranslateIcon,
  Notifications as NotificationsIcon,
  Settings as SettingsIcon,
  Logout as LogoutIcon,
  Inventory2 as ProductsIcon,
  Category as CategoriesIcon,
  Store as StoresIcon,
  Image as ContentIcon,
  People as UsersIcon,
  Business as OrganizationsIcon,
  Map as RegionsIcon,
  Security as RolesIcon,
  ShoppingCart as OrdersIcon,
  Analytics as AnalyticsIcon,
  Apps as PlaceholderLogoIcon,
} from '@mui/icons-material';
import { useThemeMode } from '@contexts/ThemeContext';
import { useAuth } from '@contexts/AuthContext';
import { componentSpacing } from '@theme/spacing';

interface NavMenuItem {
  id: string;
  labelKey: string;
  descKey: string;
  path: string;
  icon: React.ReactNode;
}

interface NavDropdown {
  id: string;
  labelKey: string;
  items: NavMenuItem[];
}

// NavButton Props Interface
interface NavButtonProps {
  label: string;
  isActive: boolean;
  hasDropdown?: boolean;
  isDropdownOpen?: boolean;
  onClick: () => void;
  onMouseEnter?: () => void;
  onMouseLeave?: () => void;
  theme: Theme;
}

// NavButton extracted as memoized component to prevent re-renders
const NavButton = memo<NavButtonProps>(({ 
  label, 
  isActive, 
  hasDropdown, 
  isDropdownOpen, 
  onClick, 
  onMouseEnter, 
  onMouseLeave,
  theme 
}) => (
  <Box
    component="button"
    onClick={onClick}
    onMouseEnter={onMouseEnter}
    onMouseLeave={onMouseLeave}
    sx={{
      display: 'flex',
      alignItems: 'center',
      gap: 0.5,
      px: 3.5,
      py: 1.25,
      border: 'none',
      borderRadius: '9999px',
      bgcolor: isActive || isDropdownOpen
        ? alpha(theme.palette.primary.main, 0.1)
        : 'transparent',
      color: isActive || isDropdownOpen
        ? 'primary.main'
        : 'text.primary',
      cursor: 'pointer',
      transition: 'all 0.2s ease',
      fontWeight: 600,
      fontSize: '1rem',
      fontFamily: 'inherit',
      '&:hover': {
        bgcolor: isActive || isDropdownOpen
          ? alpha(theme.palette.primary.main, 0.15)
          : alpha(theme.palette.action.hover, 0.08),
      },
    }}
  >
    {label}
    {hasDropdown && (
      <ChevronDownIcon
        sx={{
          fontSize: 16,
          transform: isDropdownOpen ? 'rotate(180deg)' : 'rotate(0deg)',
          transition: 'transform 0.2s ease',
        }}
      />
    )}
  </Box>
));
NavButton.displayName = 'NavButton';

// DropdownContent Props Interface
interface DropdownContentProps {
  items: NavMenuItem[];
  onNavigate: (path: string) => void;
  isPathActive: (path: string) => boolean;
  t: (key: string) => string;
  theme: Theme;
}

// DropdownContent extracted as memoized component to prevent re-renders
const DropdownContent = memo<DropdownContentProps>(({ 
  items, 
  onNavigate, 
  isPathActive, 
  t, 
  theme 
}) => (
  <Box
    sx={{
      display: 'grid',
      gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)' },
      gap: 1.5,
      p: 2.5,
    }}
  >
    {items.map((item) => (
      <ButtonBase
        key={item.id}
        onClick={() => onNavigate(item.path)}
        sx={{
          display: 'flex',
          alignItems: 'flex-start',
          gap: 2,
          p: 2.5,
          borderRadius: 2,
          cursor: 'pointer',
          bgcolor: isPathActive(item.path)
            ? alpha(theme.palette.primary.main, 0.08)
            : 'transparent',
          textAlign: 'left',
          width: '100%',
          justifyContent: 'flex-start',
          transition: 'all 0.2s ease',
          '&:hover': {
            bgcolor: alpha(theme.palette.action.hover, 0.12),
          },
        }}
      >
        <Box
          sx={{
            width: 44,
            height: 44,
            borderRadius: 2,
            bgcolor: isPathActive(item.path)
              ? alpha(theme.palette.primary.main, 0.1)
              : alpha(theme.palette.action.hover, 0.06),
            color: isPathActive(item.path) ? 'primary.main' : 'text.secondary',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}
        >
          {item.icon}
        </Box>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography
            variant="body1"
            sx={{
              fontWeight: 600,
              color: isPathActive(item.path) ? 'primary.main' : 'text.primary',
            }}
          >
            {t(item.labelKey)}
          </Typography>
          <Typography
            variant="body2"
            color="text.secondary"
            sx={{ display: 'block', mt: 0.5 }}
          >
            {t(item.descKey)}
          </Typography>
        </Box>
      </ButtonBase>
    ))}
  </Box>
));
DropdownContent.displayName = 'DropdownContent';

const manageItems: NavMenuItem[] = [
  { id: 'products', labelKey: 'nav.products', descKey: 'nav.productsDesc', path: '/products', icon: <ProductsIcon /> },
  { id: 'categories', labelKey: 'nav.categories', descKey: 'nav.categoriesDesc', path: '/categories', icon: <CategoriesIcon /> },
  { id: 'stores', labelKey: 'nav.stores', descKey: 'nav.storesDesc', path: '/stores', icon: <StoresIcon /> },
  { id: 'content', labelKey: 'nav.content', descKey: 'nav.contentDesc', path: '/content', icon: <ContentIcon /> },
];

const networkItems: NavMenuItem[] = [
  // Row 1: Users, Orders
  { id: 'users', labelKey: 'nav.users', descKey: 'nav.usersDesc', path: '/users', icon: <UsersIcon /> },
  { id: 'orders', labelKey: 'nav.orders', descKey: 'nav.ordersDesc', path: '/orders', icon: <OrdersIcon /> },
  // Row 2: Regions, Notifications
  { id: 'regions', labelKey: 'nav.regions', descKey: 'nav.regionsDesc', path: '/regions', icon: <RegionsIcon /> },
  { id: 'notifications', labelKey: 'nav.notifications', descKey: 'nav.notificationsDesc', path: '/notifications', icon: <NotificationsIcon /> },
  // Row 3: Organizations, Roles
  { id: 'organizations', labelKey: 'nav.organizations', descKey: 'nav.organizationsDesc', path: '/organizations', icon: <OrganizationsIcon /> },
  { id: 'roles', labelKey: 'nav.roles', descKey: 'nav.rolesDesc', path: '/roles', icon: <RolesIcon /> },
];

const navDropdowns: NavDropdown[] = [
  { id: 'manage', labelKey: 'nav.manage', items: manageItems },
  { id: 'network', labelKey: 'nav.network', items: networkItems },
];

interface HeaderProps {
  onMenuClick?: () => void;
}

const Header: React.FC<HeaderProps> = () => {
  const { t, i18n } = useTranslation();
  const theme = useTheme();
  const navigate = useNavigate();
  const location = useLocation();
  const { mode, toggleTheme } = useThemeMode();
  const { user, logout } = useAuth();

  // State for menus
  const [activeDropdown, setActiveDropdown] = useState<string | null>(null);
  const [profileAnchor, setProfileAnchor] = useState<null | HTMLElement>(null);
  const [langAnchor, setLangAnchor] = useState<null | HTMLElement>(null);
  const [notifAnchor, setNotifAnchor] = useState<null | HTMLElement>(null);
  const [mobileOpen, setMobileOpen] = useState(false);

  // Refs for dropdown positioning
  const dropdownRefs = useRef<{ [key: string]: HTMLElement | null }>({});
  
  // Timeout ref for delayed dropdown close
  const closeTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  
  // Flag to prevent hover from reopening dropdown right after navigation
  const justNavigatedRef = useRef(false);

  // Check if current path is in a dropdown
  const isPathInDropdown = (items: NavMenuItem[]) => {
    return items.some((item) => {
      if (item.path === '/') return location.pathname === '/';
      return location.pathname.startsWith(item.path);
    });
  };

  // Check if path is active
  const isPathActive = (path: string) => {
    if (path === '/') return location.pathname === '/';
    return location.pathname.startsWith(path);
  };

  const handleDropdownOpen = (id: string) => {
    // Don't reopen if we just navigated
    if (justNavigatedRef.current) {
      return;
    }
    // Clear any pending close timeout
    if (closeTimeoutRef.current) {
      clearTimeout(closeTimeoutRef.current);
      closeTimeoutRef.current = null;
    }
    setActiveDropdown(id);
  };

  const handleDropdownClose = () => {
    // Use timeout to allow moving between button and dropdown
    closeTimeoutRef.current = setTimeout(() => {
      setActiveDropdown(null);
    }, 150);
  };
  
  const cancelDropdownClose = () => {
    if (closeTimeoutRef.current) {
      clearTimeout(closeTimeoutRef.current);
      closeTimeoutRef.current = null;
    }
  };

  const handleNavigation = (path: string) => {
    // Clear any pending close timeout first
    if (closeTimeoutRef.current) {
      clearTimeout(closeTimeoutRef.current);
      closeTimeoutRef.current = null;
    }
    
    // Set flag to prevent hover from reopening dropdown
    justNavigatedRef.current = true;
    
    // Close dropdown and navigate
    setActiveDropdown(null);
    setMobileOpen(false);
    navigate(path);
    
    // Reset the flag after a short delay (after mouse events settle)
    setTimeout(() => {
      justNavigatedRef.current = false;
    }, 300);
  };

  const handleProfileOpen = (event: React.MouseEvent<HTMLElement>) => {
    setProfileAnchor(event.currentTarget);
  };

  const handleProfileClose = () => {
    setProfileAnchor(null);
  };

  const handleLangOpen = (event: React.MouseEvent<HTMLElement>) => {
    setLangAnchor(langAnchor ? null : event.currentTarget);
  };

  const handleLangClose = () => {
    setLangAnchor(null);
  };

  const handleLanguageChange = (lang: string) => {
    i18n.changeLanguage(lang);
    handleLangClose();
  };

  const handleNotifOpen = (event: React.MouseEvent<HTMLElement>) => {
    setNotifAnchor(event.currentTarget);
  };

  const handleNotifClose = () => {
    setNotifAnchor(null);
  };

  const handleLogout = () => {
    handleProfileClose();
    logout();
  };

  const handleMobileToggle = () => {
    setMobileOpen(!mobileOpen);
    setActiveDropdown(null);
  };

  // Ref for the popper content
  const popperContentRef = useRef<HTMLDivElement | null>(null);

  // Cleanup timeout on unmount to prevent memory leaks
  useEffect(() => {
    return () => {
      if (closeTimeoutRef.current) {
        clearTimeout(closeTimeoutRef.current);
      }
    };
  }, []);

  // Close dropdown on click away
  useEffect(() => {
    const handleClickAway = (event: MouseEvent) => {
      if (activeDropdown) {
        const dropdownElement = dropdownRefs.current[activeDropdown];
        const popperElement = popperContentRef.current;
        const target = event.target as Node;
        
        // Check if click is outside both the nav button AND the popper content
        const isOutsideNavButton = dropdownElement && !dropdownElement.contains(target);
        const isOutsidePopper = !popperElement || !popperElement.contains(target);
        
        if (isOutsideNavButton && isOutsidePopper) {
          setActiveDropdown(null);
        }
      }
    };

    document.addEventListener('mousedown', handleClickAway);
    return () => document.removeEventListener('mousedown', handleClickAway);
  }, [activeDropdown]);

  return (
    <>
      <AppBar
        position="fixed"
        elevation={0}
        sx={{
          bgcolor: 'background.default',
          borderBottom: `1px solid ${alpha(theme.palette.divider, 0.08)}`,
        }}
      >
        <Toolbar
          sx={{
            height: componentSpacing.headerHeight,
            px: { xs: 2, sm: 3 },
          }}
        >
          {/* Mobile Menu Button */}
          <IconButton
            onClick={handleMobileToggle}
            sx={{
              display: { xs: 'flex', md: 'none' },
              mr: 1,
              color: 'text.primary',
            }}
          >
            {mobileOpen ? <CloseIcon /> : <MenuIcon />}
          </IconButton>

          {/* Logo & Brand */}
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1.5,
              cursor: 'pointer',
              mr: { xs: 'auto', md: 4 },
            }}
            onClick={() => handleNavigation('/')}
          >
            <Box
              sx={{
                width: 36,
                height: 36,
                borderRadius: 1.5,
                bgcolor: alpha(theme.palette.primary.main, 0.1),
                color: 'primary.main',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <PlaceholderLogoIcon sx={{ fontSize: 22 }} />
            </Box>
            <Typography
              sx={{
                fontWeight: 700,
                fontSize: '1.1rem',
                color: 'primary.main',
                letterSpacing: '-0.01em',
                display: { xs: 'none', sm: 'block' },
              }}
            >
              EXPO to WORLD
            </Typography>
          </Box>

          {/* Desktop Navigation - Centered */}
          <Box
            sx={{
              display: { xs: 'none', md: 'flex' },
              flex: 1,
              justifyContent: 'center',
              alignItems: 'center',
              gap: 1,
            }}
          >
            {/* Dropdown Menus */}
            {navDropdowns.map((dropdown) => (
              <Box
                key={dropdown.id}
                ref={(el) => (dropdownRefs.current[dropdown.id] = el as HTMLElement)}
                onMouseEnter={() => handleDropdownOpen(dropdown.id)}
                onMouseLeave={() => handleDropdownClose()}
                sx={{ position: 'relative' }}
              >
                <NavButton
                  label={t(dropdown.labelKey)}
                  isActive={isPathInDropdown(dropdown.items)}
                  hasDropdown
                  isDropdownOpen={activeDropdown === dropdown.id}
                  onClick={() => handleDropdownOpen(dropdown.id)}
                  theme={theme}
                />

                {/* Dropdown Panel */}
                <Popper
                  open={activeDropdown === dropdown.id}
                  anchorEl={dropdownRefs.current[dropdown.id]}
                  placement="bottom-start"
                  transition
                  sx={{ zIndex: theme.zIndex.appBar + 1 }}
                >
                  {({ TransitionProps }) => (
                    <Fade {...TransitionProps} timeout={200}>
                      <Paper
                        ref={popperContentRef}
                        elevation={8}
                        onMouseEnter={cancelDropdownClose}
                        onMouseLeave={() => handleDropdownClose()}
                        sx={{
                          mt: 1,
                          minWidth: 440,
                          borderRadius: 3,
                          border: `1px solid ${alpha(theme.palette.divider, 0.15)}`,
                          bgcolor: theme.palette.mode === 'dark' 
                            ? 'rgba(30, 30, 30, 0.98)' 
                            : 'rgba(255, 255, 255, 0.98)',
                          boxShadow: theme.palette.mode === 'dark'
                            ? '0 20px 60px rgba(0,0,0,0.6), 0 8px 24px rgba(0,0,0,0.4)'
                            : '0 20px 60px rgba(0,0,0,0.18), 0 8px 24px rgba(0,0,0,0.12)',
                          overflow: 'hidden',
                          backdropFilter: 'blur(10px)',
                        }}
                      >
                        <DropdownContent 
                          items={dropdown.items} 
                          onNavigate={handleNavigation}
                          isPathActive={isPathActive}
                          t={t}
                          theme={theme}
                        />
                      </Paper>
                    </Fade>
                  )}
                </Popper>
              </Box>
            ))}

            {/* Standalone Nav Items */}
            <NavButton
              label={t('nav.analytics')}
              isActive={isPathActive('/analytics')}
              onClick={() => handleNavigation('/analytics')}
              theme={theme}
            />
          </Box>

          {/* Right Actions */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            {/* Theme Toggle */}
            <Tooltip title={mode === 'light' ? t('settings.darkMode') : t('settings.lightMode')}>
              <IconButton onClick={toggleTheme} sx={{ color: 'text.secondary' }}>
                {mode === 'light' ? <MoonIcon /> : <SunIcon />}
              </IconButton>
            </Tooltip>

            {/* Language Selector */}
            <Box sx={{ position: 'relative' }}>
              <Tooltip 
                title={t('settings.language')}
                open={!Boolean(langAnchor) ? undefined : false}
              >
                <IconButton 
                  onClick={handleLangOpen} 
                  sx={{ 
                    color: Boolean(langAnchor) ? 'primary.main' : 'text.secondary',
                    bgcolor: Boolean(langAnchor) ? alpha(theme.palette.primary.main, 0.1) : 'transparent',
                    '&:hover': {
                      bgcolor: Boolean(langAnchor) 
                        ? alpha(theme.palette.primary.main, 0.15) 
                        : alpha(theme.palette.action.hover, 0.08),
                    },
                  }}
                >
                  <TranslateIcon />
                </IconButton>
              </Tooltip>
              <Popper
                open={Boolean(langAnchor)}
                anchorEl={langAnchor}
                placement="bottom-end"
                transition
                sx={{ zIndex: theme.zIndex.modal + 1 }}
              >
                {({ TransitionProps }) => (
                  <Fade {...TransitionProps} timeout={200}>
                    <Box>
                      <ClickAwayListener onClickAway={handleLangClose}>
                        <Box
                          sx={{
                            mt: 1,
                            p: 0.75,
                            display: 'flex',
                            flexDirection: 'column',
                            gap: 0.5,
                          }}
                        >
                          {/* English Option */}
                          <ButtonBase
                            onClick={() => handleLanguageChange('en')}
                            sx={{
                              height: 36,
                              px: 2,
                              borderRadius: 1.5,
                              bgcolor: i18n.language === 'en'
                                ? theme.palette.primary.main
                                : theme.palette.mode === 'dark'
                                  ? 'rgba(255, 255, 255, 0.08)'
                                  : 'rgba(255, 255, 255, 0.9)',
                              color: i18n.language === 'en'
                                ? '#fff'
                                : 'text.primary',
                              fontWeight: 500,
                              fontSize: '0.875rem',
                              minWidth: 100,
                              justifyContent: 'center',
                              backdropFilter: i18n.language === 'en' ? 'none' : 'blur(8px)',
                              border: i18n.language === 'en'
                                ? 'none'
                                : `1px solid ${alpha(theme.palette.divider, 0.1)}`,
                              transition: 'all 0.2s ease',
                              '&:hover': {
                                bgcolor: i18n.language === 'en'
                                  ? theme.palette.primary.dark
                                  : theme.palette.mode === 'dark'
                                    ? 'rgba(255, 255, 255, 0.12)'
                                    : 'rgba(255, 255, 255, 1)',
                              },
                            }}
                          >
                            {t('settings.languages.en')}
                          </ButtonBase>
                          {/* Chinese Option */}
                          <ButtonBase
                            onClick={() => handleLanguageChange('zh')}
                            sx={{
                              height: 36,
                              px: 2,
                              borderRadius: 1.5,
                              bgcolor: i18n.language === 'zh'
                                ? theme.palette.primary.main
                                : theme.palette.mode === 'dark'
                                  ? 'rgba(255, 255, 255, 0.08)'
                                  : 'rgba(255, 255, 255, 0.9)',
                              color: i18n.language === 'zh'
                                ? '#fff'
                                : 'text.primary',
                              fontWeight: 500,
                              fontSize: '0.875rem',
                              minWidth: 100,
                              justifyContent: 'center',
                              backdropFilter: i18n.language === 'zh' ? 'none' : 'blur(8px)',
                              border: i18n.language === 'zh'
                                ? 'none'
                                : `1px solid ${alpha(theme.palette.divider, 0.1)}`,
                              transition: 'all 0.2s ease',
                              '&:hover': {
                                bgcolor: i18n.language === 'zh'
                                  ? theme.palette.primary.dark
                                  : theme.palette.mode === 'dark'
                                    ? 'rgba(255, 255, 255, 0.12)'
                                    : 'rgba(255, 255, 255, 1)',
                              },
                            }}
                          >
                            {t('settings.languages.zh')}
                          </ButtonBase>
                        </Box>
                      </ClickAwayListener>
                    </Box>
                  </Fade>
                )}
              </Popper>
            </Box>

            {/* Notifications */}
            <Tooltip 
              title={t('common.notifications')}
              open={!Boolean(notifAnchor) ? undefined : false}
            >
              <IconButton onClick={handleNotifOpen} sx={{ color: 'text.secondary' }}>
                <Badge badgeContent={3} color="error">
                  <NotificationsIcon />
                </Badge>
              </IconButton>
            </Tooltip>
            <Menu
              anchorEl={notifAnchor}
              open={Boolean(notifAnchor)}
              onClose={handleNotifClose}
              anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
              transformOrigin={{ vertical: 'top', horizontal: 'right' }}
              disableScrollLock
              slotProps={{
                paper: {
                  sx: {
                    width: 320,
                    maxHeight: 400,
                    mt: 1,
                    borderRadius: 2,
                    border: `1px solid ${alpha(theme.palette.divider, 0.15)}`,
                    bgcolor: theme.palette.mode === 'dark' 
                      ? 'rgba(30, 30, 30, 0.98)' 
                      : 'rgba(255, 255, 255, 0.98)',
                    boxShadow: theme.palette.mode === 'dark'
                      ? '0 20px 60px rgba(0,0,0,0.6), 0 8px 24px rgba(0,0,0,0.4)'
                      : '0 20px 60px rgba(0,0,0,0.18), 0 8px 24px rgba(0,0,0,0.12)',
                    backdropFilter: 'blur(10px)',
                  },
                },
                root: {
                  sx: {
                    '& .MuiBackdrop-root': {
                      backgroundColor: 'transparent',
                    },
                  },
                },
              }}
            >
              {/* TODO: DUMMY DATA - Replace with real notifications */}
              <MenuItem>
                <Box>
                  <Typography variant="subtitle2">{t('common.newOrder', { id: '1234' })}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    {t('common.minutesAgo', { count: 2 })}
                  </Typography>
                </Box>
              </MenuItem>
              <MenuItem>
                <Box>
                  <Typography variant="subtitle2">{t('common.lowStockAlert')}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    {t('common.productsNeedRestocking', { count: 5 })}
                  </Typography>
                </Box>
              </MenuItem>
              <MenuItem>
                <Box>
                  <Typography variant="subtitle2">{t('common.newUserRegistration')}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    {t('common.minutesAgo', { count: 15 })}
                  </Typography>
                </Box>
              </MenuItem>
              <Divider />
              <MenuItem sx={{ justifyContent: 'center' }}>
                <Typography variant="body2" color="primary">
                  {t('common.viewAll')}
                </Typography>
              </MenuItem>
            </Menu>

            {/* Profile Menu */}
            <Tooltip 
              title={t('nav.settings')}
              open={!Boolean(profileAnchor) ? undefined : false}
            >
              <IconButton onClick={handleProfileOpen} sx={{ p: 0.5, ml: 1 }}>
                <Avatar
                  alt={user?.username || 'Admin'}
                  sx={{
                    width: 36,
                    height: 36,
                    bgcolor: 'primary.main',
                    fontSize: '0.875rem',
                  }}
                >
                  {user?.username?.charAt(0).toUpperCase() || 'A'}
                </Avatar>
              </IconButton>
            </Tooltip>
            <Menu
              anchorEl={profileAnchor}
              open={Boolean(profileAnchor)}
              onClose={handleProfileClose}
              anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
              transformOrigin={{ vertical: 'top', horizontal: 'right' }}
              disableScrollLock
              slotProps={{
                paper: {
                  sx: {
                    width: 200,
                    mt: 1,
                    borderRadius: 2,
                    border: `1px solid ${alpha(theme.palette.divider, 0.15)}`,
                    bgcolor: theme.palette.mode === 'dark' 
                      ? 'rgba(30, 30, 30, 0.98)' 
                      : 'rgba(255, 255, 255, 0.98)',
                    boxShadow: theme.palette.mode === 'dark'
                      ? '0 20px 60px rgba(0,0,0,0.6), 0 8px 24px rgba(0,0,0,0.4)'
                      : '0 20px 60px rgba(0,0,0,0.18), 0 8px 24px rgba(0,0,0,0.12)',
                    backdropFilter: 'blur(10px)',
                  },
                },
                root: {
                  sx: {
                    '& .MuiBackdrop-root': {
                      backgroundColor: 'transparent',
                    },
                  },
                },
              }}
            >
              <Box sx={{ px: 2, py: 1.5 }}>
                <Typography variant="subtitle2" fontWeight={600}>
                  {user?.username || 'Admin'}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {user?.email || 'admin@expotoworld.com'}
                </Typography>
              </Box>
              <Divider />
              <MenuItem onClick={() => { handleProfileClose(); handleNavigation('/settings'); }}>
                <ListItemIcon>
                  <SettingsIcon fontSize="small" />
                </ListItemIcon>
                <ListItemText>{t('nav.settings')}</ListItemText>
              </MenuItem>
              <MenuItem onClick={handleLogout}>
                <ListItemIcon>
                  <LogoutIcon fontSize="small" />
                </ListItemIcon>
                <ListItemText>{t('auth.logout')}</ListItemText>
              </MenuItem>
            </Menu>
          </Box>
        </Toolbar>
      </AppBar>

      {/* Mobile Navigation Drawer */}
      <Collapse
        in={mobileOpen}
        sx={{
          position: 'fixed',
          top: componentSpacing.headerHeight,
          left: 0,
          right: 0,
          zIndex: theme.zIndex.appBar,
          bgcolor: 'background.paper',
          borderBottom: `1px solid ${alpha(theme.palette.divider, 0.1)}`,
          maxHeight: `calc(100vh - ${componentSpacing.headerHeight}px)`,
          overflowY: 'auto',
          display: { xs: 'block', md: 'none' },
        }}
      >
        <List sx={{ p: 2 }}>
          {/* Dashboard */}
          <ListItem disablePadding sx={{ mb: 0.5 }}>
            <ListItemButton
              onClick={() => handleNavigation('/')}
              sx={{
                borderRadius: 2,
                bgcolor: isPathActive('/') && location.pathname === '/'
                  ? alpha(theme.palette.primary.main, 0.1)
                  : 'transparent',
              }}
            >
              <ListItemText
                primary={t('nav.dashboard')}
                primaryTypographyProps={{
                  fontWeight: isPathActive('/') && location.pathname === '/' ? 600 : 500,
                  color: isPathActive('/') && location.pathname === '/' ? 'primary.main' : 'text.primary',
                }}
              />
            </ListItemButton>
          </ListItem>

          {/* Dropdown Sections */}
          {navDropdowns.map((dropdown) => (
            <Box key={dropdown.id} sx={{ mb: 1 }}>
              <Typography
                variant="overline"
                color="text.secondary"
                sx={{ px: 2, display: 'block', mb: 1 }}
              >
                {t(dropdown.labelKey)}
              </Typography>
              {dropdown.items.map((item) => (
                <ListItem key={item.id} disablePadding sx={{ mb: 0.5 }}>
                  <ListItemButton
                    onClick={() => handleNavigation(item.path)}
                    sx={{
                      borderRadius: 2,
                      bgcolor: isPathActive(item.path)
                        ? alpha(theme.palette.primary.main, 0.1)
                        : 'transparent',
                    }}
                  >
                    <ListItemIcon
                      sx={{
                        minWidth: 40,
                        color: isPathActive(item.path) ? 'primary.main' : 'text.secondary',
                      }}
                    >
                      {item.icon}
                    </ListItemIcon>
                    <ListItemText
                      primary={t(item.labelKey)}
                      secondary={t(item.descKey)}
                      primaryTypographyProps={{
                        fontWeight: isPathActive(item.path) ? 600 : 500,
                        color: isPathActive(item.path) ? 'primary.main' : 'text.primary',
                        fontSize: '0.875rem',
                      }}
                      secondaryTypographyProps={{
                        fontSize: '0.75rem',
                      }}
                    />
                  </ListItemButton>
                </ListItem>
              ))}
            </Box>
          ))}

          {/* Standalone Items */}
          <Divider sx={{ my: 1 }} />
          <ListItem disablePadding>
            <ListItemButton
              onClick={() => handleNavigation('/analytics')}
              sx={{
                borderRadius: 2,
                bgcolor: isPathActive('/analytics')
                  ? alpha(theme.palette.primary.main, 0.1)
                  : 'transparent',
              }}
            >
              <ListItemIcon
                sx={{
                  minWidth: 40,
                  color: isPathActive('/analytics') ? 'primary.main' : 'text.secondary',
                }}
              >
                <AnalyticsIcon />
              </ListItemIcon>
              <ListItemText
                primary={t('nav.analytics')}
                secondary={t('nav.analyticsDesc')}
                primaryTypographyProps={{
                  fontWeight: isPathActive('/analytics') ? 600 : 500,
                  color: isPathActive('/analytics') ? 'primary.main' : 'text.primary',
                  fontSize: '0.875rem',
                }}
                secondaryTypographyProps={{
                  fontSize: '0.75rem',
                }}
              />
            </ListItemButton>
          </ListItem>
        </List>
      </Collapse>
    </>
  );
};

export default Header;
