import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  AppBar,
  Toolbar,
  IconButton,
  Typography,
  Box,
  Avatar,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider,
  Tooltip,
  Badge,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Brightness4 as DarkModeIcon,
  Brightness7 as LightModeIcon,
  Notifications as NotificationsIcon,
  Person as ProfileIcon,
  Logout as LogoutIcon,
  Language as LanguageIcon,
} from '@mui/icons-material';
import { useThemeMode } from '@contexts/ThemeContext';
import { useAuth } from '@contexts/AuthContext';
import { componentSpacing } from '@theme/spacing';

interface HeaderProps {
  onMenuClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
  const { t, i18n } = useTranslation();
  const { mode, toggleTheme } = useThemeMode();
  const { user, logout } = useAuth();

  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [langAnchorEl, setLangAnchorEl] = useState<null | HTMLElement>(null);
  const [notifAnchorEl, setNotifAnchorEl] = useState<null | HTMLElement>(null);

  const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleProfileMenuClose = () => {
    setAnchorEl(null);
  };

  const handleLangMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setLangAnchorEl(event.currentTarget);
  };

  const handleLangMenuClose = () => {
    setLangAnchorEl(null);
  };

  const handleLanguageChange = (lang: string) => {
    i18n.changeLanguage(lang);
    handleLangMenuClose();
  };

  const handleNotifMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setNotifAnchorEl(event.currentTarget);
  };

  const handleNotifMenuClose = () => {
    setNotifAnchorEl(null);
  };

  const handleLogout = () => {
    handleProfileMenuClose();
    logout();
  };

  return (
    <AppBar
      position="fixed"
      elevation={0}
      sx={{
        width: { sm: `calc(100% - ${componentSpacing.sidebarWidth}px)` },
        ml: { sm: `${componentSpacing.sidebarWidth}px` },
        bgcolor: 'background.default',
      }}
    >
      <Toolbar sx={{ height: componentSpacing.headerHeight }}>
        {/* Mobile Menu Button */}
        <IconButton
          color="inherit"
          aria-label="open drawer"
          edge="start"
          onClick={onMenuClick}
          sx={{ mr: 2, display: { sm: 'none' }, color: 'text.primary' }}
        >
          <MenuIcon />
        </IconButton>

        {/* Page Title - Could be dynamic based on route */}
        <Typography
          variant="h6"
          noWrap
          component="div"
          sx={{ display: { xs: 'none', sm: 'block' }, color: 'text.primary', fontWeight: 600 }}
        >
          {t('nav.dashboard')}
        </Typography>

        <Box sx={{ flexGrow: 1 }} />

        {/* Actions */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {/* Theme Toggle */}
          <Tooltip title={mode === 'light' ? t('settings.darkMode') : t('settings.lightMode')}>
            <IconButton onClick={toggleTheme} sx={{ color: 'text.secondary' }}>
              {mode === 'light' ? <DarkModeIcon /> : <LightModeIcon />}
            </IconButton>
          </Tooltip>

          {/* Language Selector */}
          <Tooltip title={t('settings.language')}>
            <IconButton onClick={handleLangMenuOpen} sx={{ color: 'text.secondary' }}>
              <LanguageIcon />
            </IconButton>
          </Tooltip>
          <Menu
            anchorEl={langAnchorEl}
            open={Boolean(langAnchorEl)}
            onClose={handleLangMenuClose}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: 'right' }}
          >
            <MenuItem
              selected={i18n.language === 'en'}
              onClick={() => handleLanguageChange('en')}
            >
              English
            </MenuItem>
            <MenuItem
              selected={i18n.language === 'zh'}
              onClick={() => handleLanguageChange('zh')}
            >
              中文
            </MenuItem>
          </Menu>

          {/* Notifications */}
          <Tooltip title={t('common.notifications')}>
            <IconButton onClick={handleNotifMenuOpen} sx={{ color: 'text.secondary' }}>
              <Badge badgeContent={3} color="error">
                <NotificationsIcon />
              </Badge>
            </IconButton>
          </Tooltip>
          <Menu
            anchorEl={notifAnchorEl}
            open={Boolean(notifAnchorEl)}
            onClose={handleNotifMenuClose}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: 'right' }}
            PaperProps={{ sx: { width: 320, maxHeight: 400 } }}
          >
            {/* TODO: DUMMY DATA - Replace with real notifications */}
            <MenuItem>
              <Box>
                <Typography variant="subtitle2">New Order #1234</Typography>
                <Typography variant="caption" color="text.secondary">
                  2 minutes ago
                </Typography>
              </Box>
            </MenuItem>
            <MenuItem>
              <Box>
                <Typography variant="subtitle2">Low Stock Alert</Typography>
                <Typography variant="caption" color="text.secondary">
                  5 products need restocking
                </Typography>
              </Box>
            </MenuItem>
            <MenuItem>
              <Box>
                <Typography variant="subtitle2">New User Registration</Typography>
                <Typography variant="caption" color="text.secondary">
                  15 minutes ago
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
          <Tooltip title={t('common.profile')}>
            <IconButton onClick={handleProfileMenuOpen} sx={{ p: 0.5, ml: 1 }}>
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
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleProfileMenuClose}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            transformOrigin={{ vertical: 'top', horizontal: 'right' }}
            PaperProps={{ sx: { width: 200 } }}
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
            <MenuItem onClick={handleProfileMenuClose}>
              <ListItemIcon>
                <ProfileIcon fontSize="small" />
              </ListItemIcon>
              <ListItemText>{t('common.profile')}</ListItemText>
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
  );
};

export default Header;
