import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  TextField,
  Button,
  Switch,
  Divider,
  Alert,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  ListItemSecondaryAction,
  Avatar,
} from '@mui/material';
import {
  Person as PersonIcon,
  Security as SecurityIcon,
  Notifications as NotificationsIcon,
  Language as LanguageIcon,
  Palette as ThemeIcon,
  Save as SaveIcon,
  Key as KeyIcon,
} from '@mui/icons-material';
import { useThemeMode } from '@contexts/ThemeContext';

// TODO: NEED TO FULLY IMPLEMENT - This is a placeholder page

const SettingsPage: React.FC = () => {
  const { t, i18n } = useTranslation();
  const { mode, toggleTheme } = useThemeMode();

  // Mock admin profile
  const [profile, setProfile] = React.useState({
    name: 'Admin User',
    email: 'admin@expotoworld.com',
    avatar: '',
  });

  const [notifications, setNotifications] = React.useState({
    emailOrders: true,
    emailUsers: false,
    emailReports: true,
    pushOrders: true,
    pushLowStock: true,
  });

  const handleLanguageChange = (lang: string) => {
    i18n.changeLanguage(lang);
  };

  return (
    <Box>
      <Grid container spacing={3}>
        {/* Profile Settings */}
        <Grid item xs={12} md={6}>
          <Card elevation={0}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                <PersonIcon color="primary" />
                <Typography variant="h6">{t('settings.profile')}</Typography>
              </Box>

              <Box sx={{ display: 'flex', alignItems: 'center', gap: 3, mb: 3 }}>
                <Avatar
                  sx={{ width: 80, height: 80, bgcolor: 'primary.main', fontSize: 32 }}
                >
                  {profile.name.charAt(0)}
                </Avatar>
                <Box>
                  <Typography variant="h6">{profile.name}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    {profile.email}
                  </Typography>
                  <Button size="small" sx={{ mt: 1 }}>
                    {t('settings.changeAvatar')}
                  </Button>
                </Box>
              </Box>

              <TextField
                fullWidth
                label={t('settings.displayName')}
                value={profile.name}
                onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                sx={{ mb: 2 }}
              />

              <TextField
                fullWidth
                label={t('settings.email')}
                value={profile.email}
                onChange={(e) => setProfile({ ...profile, email: e.target.value })}
                sx={{ mb: 2 }}
              />

              <Button variant="contained" startIcon={<SaveIcon />}>
                {t('settings.saveProfile')}
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Security Settings */}
        <Grid item xs={12} md={6}>
          <Card elevation={0}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                <SecurityIcon color="primary" />
                <Typography variant="h6">{t('settings.security')}</Typography>
              </Box>

              <Alert severity="info" sx={{ mb: 3 }}>
                {t('settings.securityInfo')}
              </Alert>

              <List disablePadding>
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <KeyIcon />
                  </ListItemIcon>
                  <ListItemText
                    primary={t('settings.password')}
                    secondary={t('settings.passwordUpdated', { date: '30 days ago' })}
                  />
                  <ListItemSecondaryAction>
                    <Button size="small" variant="outlined">
                      {t('settings.changePassword')}
                    </Button>
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider component="li" />
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <SecurityIcon />
                  </ListItemIcon>
                  <ListItemText
                    primary={t('settings.twoFactor')}
                    secondary={t('settings.twoFactorDescription')}
                  />
                  <ListItemSecondaryAction>
                    <Switch defaultChecked={false} />
                  </ListItemSecondaryAction>
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Appearance Settings */}
        <Grid item xs={12} md={6}>
          <Card elevation={0}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                <ThemeIcon color="primary" />
                <Typography variant="h6">{t('settings.appearance')}</Typography>
              </Box>

              <List disablePadding>
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <ThemeIcon />
                  </ListItemIcon>
                  <ListItemText
                    primary={t('settings.darkMode')}
                    secondary={t('settings.darkModeDescription')}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={mode === 'dark'}
                      onChange={toggleTheme}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider component="li" />
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <LanguageIcon />
                  </ListItemIcon>
                  <ListItemText
                    primary={t('settings.language')}
                    secondary={t('settings.languageDescription')}
                  />
                  <ListItemSecondaryAction>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <Button
                        size="small"
                        variant={i18n.language === 'en' ? 'contained' : 'outlined'}
                        onClick={() => handleLanguageChange('en')}
                      >
                        EN
                      </Button>
                      <Button
                        size="small"
                        variant={i18n.language === 'zh' ? 'contained' : 'outlined'}
                        onClick={() => handleLanguageChange('zh')}
                      >
                        中文
                      </Button>
                    </Box>
                  </ListItemSecondaryAction>
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Notification Settings */}
        <Grid item xs={12} md={6}>
          <Card elevation={0}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                <NotificationsIcon color="primary" />
                <Typography variant="h6">{t('settings.notifications')}</Typography>
              </Box>

              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                {t('settings.emailNotifications')}
              </Typography>
              <List disablePadding>
                <ListItem sx={{ px: 0 }}>
                  <ListItemText primary={t('settings.newOrders')} />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.emailOrders}
                      onChange={(e) =>
                        setNotifications({ ...notifications, emailOrders: e.target.checked })
                      }
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <ListItem sx={{ px: 0 }}>
                  <ListItemText primary={t('settings.newUsers')} />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.emailUsers}
                      onChange={(e) =>
                        setNotifications({ ...notifications, emailUsers: e.target.checked })
                      }
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <ListItem sx={{ px: 0 }}>
                  <ListItemText primary={t('settings.weeklyReports')} />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.emailReports}
                      onChange={(e) =>
                        setNotifications({ ...notifications, emailReports: e.target.checked })
                      }
                    />
                  </ListItemSecondaryAction>
                </ListItem>
              </List>

              <Divider sx={{ my: 2 }} />

              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                {t('settings.pushNotifications')}
              </Typography>
              <List disablePadding>
                <ListItem sx={{ px: 0 }}>
                  <ListItemText primary={t('settings.newOrdersAlert')} />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.pushOrders}
                      onChange={(e) =>
                        setNotifications({ ...notifications, pushOrders: e.target.checked })
                      }
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <ListItem sx={{ px: 0 }}>
                  <ListItemText primary={t('settings.lowStockAlert')} />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.pushLowStock}
                      onChange={(e) =>
                        setNotifications({ ...notifications, pushLowStock: e.target.checked })
                      }
                    />
                  </ListItemSecondaryAction>
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Future RBAC Placeholder */}
        <Grid item xs={12}>
          <Card elevation={0} sx={{ bgcolor: 'action.hover' }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                <SecurityIcon color="disabled" />
                <Typography variant="h6" color="text.secondary">
                  {t('settings.rolesPermissions')}
                </Typography>
              </Box>
              <Alert severity="info">
                {/* TODO: NEED TO FULLY IMPLEMENT - RBAC for manufacturers, logistics, partners */}
                {t('settings.rbacComingSoon')}
              </Alert>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                {t('settings.rbacDescription')}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default SettingsPage;
