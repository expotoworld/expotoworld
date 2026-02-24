/**
 * EXPO to WORLD Admin Panel - MUI Theme Configuration
 * Creates both light and dark themes with the design system
 */

import { createTheme, type ThemeOptions, type Theme } from '@mui/material/styles';
import * as colors from './colors';
import { typography as typographyTokens, fontFamily } from './typography';
import { borderRadius, spacing as spacingTokens } from './spacing';

// Common theme options shared between light and dark
const commonOptions: ThemeOptions = {
  shape: {
    borderRadius: borderRadius.md,
  },
  typography: {
    fontFamily: fontFamily.primary,
    h1: typographyTokens.h1,
    h2: typographyTokens.h2,
    h3: typographyTokens.h3,
    h4: {
      ...typographyTokens.h3,
      fontSize: '1rem',
    },
    h5: {
      ...typographyTokens.body,
      fontWeight: 600,
    },
    h6: {
      ...typographyTokens.body,
      fontWeight: 600,
    },
    body1: typographyTokens.body,
    body2: typographyTokens.bodySmall,
    caption: typographyTokens.caption,
    button: typographyTokens.button,
    overline: typographyTokens.overline,
  },
  spacing: 4, // Base spacing unit (4px)
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        '*': {
          boxSizing: 'border-box',
        },
        html: {
          scrollBehavior: 'smooth',
        },
        body: {
          fontFamily: fontFamily.primary,
          WebkitFontSmoothing: 'antialiased',
          MozOsxFontSmoothing: 'grayscale',
        },
        '::-webkit-scrollbar': {
          width: '8px',
          height: '8px',
        },
        '::-webkit-scrollbar-thumb': {
          borderRadius: '4px',
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: borderRadius.md,
          textTransform: 'none',
          fontWeight: 600,
          padding: `${spacingTokens.sm}px ${spacingTokens.lg}px`,
        },
        sizeSmall: {
          padding: `${spacingTokens.xs}px ${spacingTokens.md}px`,
          fontSize: '0.8125rem',
        },
        sizeLarge: {
          padding: `${spacingTokens.md}px ${spacingTokens.xl}px`,
          fontSize: '1rem',
        },
      },
      defaultProps: {
        disableElevation: true,
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: borderRadius.lg,
          backdropFilter: 'blur(10px)',
          WebkitBackdropFilter: 'blur(10px)',
          transition: 'transform 0.2s ease, box-shadow 0.2s ease',
          '&:hover': {
            transform: 'translateY(-2px)',
          },
        },
      },
      defaultProps: {
        elevation: 0,
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: borderRadius.lg,
          backgroundImage: 'none',
          backdropFilter: 'blur(10px)',
          WebkitBackdropFilter: 'blur(10px)',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: borderRadius.sm,
          },
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: borderRadius.xs,
          fontWeight: 500,
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        root: {
          fontSize: '0.875rem',
          borderBottom: 'none',
        },
        head: {
          fontWeight: 600,
        },
      },
    },
    MuiDivider: {
      styleOverrides: {
        root: {
          borderColor: 'inherit',
          opacity: 0.5,
        },
      },
    },
    MuiTooltip: {
      styleOverrides: {
        tooltip: {
          fontSize: '0.75rem',
          borderRadius: borderRadius.xs,
        },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: {
          borderRadius: borderRadius.lg,
          // Remove glassmorphism from dialogs - make them solid
          backdropFilter: 'none',
          WebkitBackdropFilter: 'none',
        },
      },
    },
    MuiBackdrop: {
      styleOverrides: {
        root: {
          backgroundColor: 'rgba(0, 0, 0, 0.85)',
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          borderRadius: 0,
        },
      },
    },
    // Fix for dropdown and popup backgrounds - ensure solid backgrounds and proper border radius clipping
    MuiMenu: {
      defaultProps: {
        // Disable backdrop dimming for menus
        slotProps: {
          backdrop: {
            invisible: true,
          },
        } as Record<string, unknown>,
      },
      styleOverrides: {
        paper: {
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          overflow: 'hidden', // This clips children to match border-radius
          borderRadius: borderRadius.lg,
        },
        list: {
          padding: 0,
        },
      },
    },
    MuiMenuItem: {
      styleOverrides: {
        root: {
          padding: '10px 16px',
          // NO border-radius on items - let parent overflow:hidden clip them
        },
      },
    },
    MuiSelect: {
      defaultProps: {
        // Make Select menus have invisible backdrop
        MenuProps: {
          disableScrollLock: true,
          // Use all methods to ensure backdrop is invisible
          hideBackdrop: true,
          BackdropProps: {
            invisible: true,
            style: { backgroundColor: 'transparent' },
          },
          slotProps: {
            backdrop: {
              invisible: true,
              style: { backgroundColor: 'transparent' },
            },
            paper: {
              sx: {
                // Ensure the menu paper doesn't get dialog styling
                position: 'relative',
              },
            },
          } as Record<string, unknown>,
        },
      },
      styleOverrides: {
        select: {
          '&:focus': {
            backgroundColor: 'transparent',
          },
        },
      },
    },
    MuiPopover: {
      defaultProps: {
        // Make Popover backdrop invisible by default
        BackdropProps: {
          invisible: true,
        },
      },
      styleOverrides: {
        paper: {
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          overflow: 'hidden',
          borderRadius: borderRadius.lg,
        },
      },
    },
    MuiAutocomplete: {
      styleOverrides: {
        paper: {
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
        },
      },
    },
  },
};

// Dark theme
export const darkTheme: Theme = createTheme({
  ...commonOptions,
  palette: {
    mode: 'dark',
    primary: {
      main: colors.themeRed,
      dark: colors.themeRedDark,
      light: colors.themeRedLight,
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: colors.blue,
      dark: colors.blueDark,
      light: colors.blueMuted,
      contrastText: '#FFFFFF',
    },
    error: {
      main: colors.themeRed,
      light: colors.themeRedLight,
      dark: colors.themeRedDark,
    },
    warning: {
      main: colors.yellow,
      light: colors.yellowLightest,
      dark: colors.yellowDark,
    },
    success: {
      main: colors.green,
      light: colors.greenLightest,
      dark: colors.greenDark,
    },
    info: {
      main: colors.blue,
      light: '#E0F2FE',
      dark: colors.blueDark,
    },
    background: {
      default: colors.darkMode.backgroundBase,
      paper: colors.darkMode.backgroundPaper,
    },
    text: {
      primary: colors.darkMode.foreground,
      secondary: colors.darkMode.foregroundMuted,
      disabled: colors.darkMode.foregroundSubtle,
    },
    divider: colors.darkMode.borderDefault,
    action: {
      active: colors.darkMode.foreground,
      hover: 'rgba(255, 255, 255, 0.08)',
      selected: 'rgba(238, 52, 50, 0.16)',
      disabled: 'rgba(255, 255, 255, 0.3)',
      disabledBackground: 'rgba(255, 255, 255, 0.12)',
    },
  },
  components: {
    ...commonOptions.components,
    MuiCssBaseline: {
      styleOverrides: {
        ...((commonOptions.components?.MuiCssBaseline?.styleOverrides as object) || {}),
        '::-webkit-scrollbar-track': {
          background: colors.darkMode.backgroundBase,
        },
        '::-webkit-scrollbar-thumb': {
          background: colors.darkMode.borderDefault,
          borderRadius: '4px',
          '&:hover': {
            background: colors.darkMode.borderHover,
          },
        },
      },
    },
    // Glassmorphism Card for Dark Mode
    MuiCard: {
      styleOverrides: {
        root: {
          background: `linear-gradient(180deg, ${colors.darkMode.cardGradientStart} 0%, ${colors.darkMode.cardGradientEnd} 100%)`,
          border: `1px solid ${colors.darkMode.glassBorder}`,
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.3)',
          '&:hover': {
            boxShadow: `0 12px 40px rgba(0, 0, 0, 0.4), 0 0 20px ${colors.darkMode.accentGlow}`,
          },
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          background: `linear-gradient(180deg, ${colors.darkMode.cardGradientStart} 0%, ${colors.darkMode.cardGradientEnd} 100%)`,
          border: `1px solid ${colors.darkMode.glassBorder}`,
        },
      },
    },
    // Ensure dropdown menus have solid backgrounds in dark mode
    MuiMenu: {
      styleOverrides: {
        paper: {
          backgroundColor: 'rgba(26, 26, 26, 0.98)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
        },
      },
    },
    MuiPopover: {
      styleOverrides: {
        paper: {
          backgroundColor: 'rgba(26, 26, 26, 0.98)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
        },
      },
    },
    MuiSelect: {
      styleOverrides: {
        root: {
          '& .MuiMenu-paper': {
            backgroundColor: 'rgba(26, 26, 26, 0.98)',
          },
        },
      },
    },
    // Make dialogs/modals have more glassmorphism
    MuiDialog: {
      styleOverrides: {
        paper: {
          backgroundColor: 'rgba(26, 26, 26, 0.75)',
          backdropFilter: 'blur(32px)',
          WebkitBackdropFilter: 'blur(32px)',
          border: `1px solid rgba(255, 255, 255, 0.1)`,
          boxShadow: '0 24px 64px rgba(0, 0, 0, 0.5)',
          // Subtle gradient shine for glassmorphism
          backgroundImage: 'linear-gradient(135deg, rgba(255, 255, 255, 0.08) 0%, rgba(255, 255, 255, 0) 50%, rgba(255, 255, 255, 0.04) 100%)',
        },
      },
    },
  },
});

// Light theme
export const lightTheme: Theme = createTheme({
  ...commonOptions,
  palette: {
    mode: 'light',
    primary: {
      main: colors.themeRed,
      dark: colors.themeRedDark,
      light: colors.themeRedLight,
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: colors.blue,
      dark: colors.blueDark,
      light: colors.blueMuted,
      contrastText: '#FFFFFF',
    },
    error: {
      main: colors.themeRed,
      light: colors.themeRedLightest,
      dark: colors.themeRedDark,
    },
    warning: {
      main: colors.yellow,
      light: colors.yellowLightest,
      dark: colors.yellowDark,
    },
    success: {
      main: colors.green,
      light: colors.greenLightest,
      dark: colors.greenDark,
    },
    info: {
      main: colors.blue,
      light: '#E0F2FE',
      dark: colors.blueDark,
    },
    background: {
      default: colors.lightMode.backgroundBase,
      paper: colors.lightMode.backgroundPaper,
    },
    text: {
      primary: colors.lightMode.foreground,
      secondary: colors.lightMode.foregroundMuted,
      disabled: colors.lightMode.foregroundSubtle,
    },
    divider: colors.lightMode.borderDefault,
    action: {
      active: colors.lightMode.foreground,
      hover: 'rgba(0, 0, 0, 0.04)',
      selected: 'rgba(238, 52, 50, 0.08)',
      disabled: 'rgba(0, 0, 0, 0.26)',
      disabledBackground: 'rgba(0, 0, 0, 0.12)',
    },
  },
  components: {
    ...commonOptions.components,
    MuiCssBaseline: {
      styleOverrides: {
        ...((commonOptions.components?.MuiCssBaseline?.styleOverrides as object) || {}),
        '::-webkit-scrollbar-track': {
          background: colors.lightMode.backgroundElevated,
        },
        '::-webkit-scrollbar-thumb': {
          background: colors.lightMode.borderDefault,
          borderRadius: '4px',
          '&:hover': {
            background: colors.lightMode.borderHover,
          },
        },
      },
    },
    // Glassmorphism Card for Light Mode
    MuiCard: {
      styleOverrides: {
        root: {
          background: `linear-gradient(180deg, ${colors.lightMode.cardGradientStart} 0%, ${colors.lightMode.cardGradientEnd} 100%)`,
          border: `1px solid ${colors.lightMode.glassBorder}`,
          boxShadow: '0 4px 24px rgba(0, 0, 0, 0.06)',
          '&:hover': {
            boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
          },
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          background: `linear-gradient(180deg, ${colors.lightMode.cardGradientStart} 0%, ${colors.lightMode.cardGradientEnd} 100%)`,
          border: `1px solid ${colors.lightMode.glassBorder}`,
        },
      },
    },
    // Ensure dropdown menus have solid backgrounds in light mode
    MuiMenu: {
      styleOverrides: {
        paper: {
          backgroundColor: 'rgba(255, 255, 255, 0.98)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.15)',
        },
      },
    },
    MuiPopover: {
      styleOverrides: {
        paper: {
          backgroundColor: 'rgba(255, 255, 255, 0.98)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.15)',
        },
      },
    },
    MuiSelect: {
      styleOverrides: {
        root: {
          '& .MuiMenu-paper': {
            backgroundColor: 'rgba(255, 255, 255, 0.98)',
          },
        },
      },
    },
    // Make dialogs/modals have more glassmorphism with depth
    MuiDialog: {
      styleOverrides: {
        paper: {
          backgroundColor: 'rgba(255, 255, 255, 0.85)',
          backdropFilter: 'blur(40px) saturate(180%)',
          WebkitBackdropFilter: 'blur(40px) saturate(180%)',
          border: `1px solid rgba(255, 255, 255, 0.5)`,
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.12), 0 24px 64px rgba(0, 0, 0, 0.15), inset 0 1px 0 rgba(255, 255, 255, 0.9)',
          // Bright top edge shine for depth
          backgroundImage: 'linear-gradient(180deg, rgba(255, 255, 255, 0.95) 0%, rgba(255, 255, 255, 0.8) 5%, rgba(255, 255, 255, 0.75) 100%)',
        },
      },
    },
  },
});

export type { Theme };
