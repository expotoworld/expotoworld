import { createTheme } from '@mui/material/styles';

// Made in World Design System Colors
const colors = {
  themeRed: '#D92525',
  lightRed: '#FFF5F5',
  primaryText: '#1A1A1A',
  secondaryText: '#6A7485',
  lightBackground: '#F7F9FC',
  white: '#FFFFFF',
};

// Create the MUI theme
const theme = createTheme({
  palette: {
    primary: {
      main: colors.themeRed,
      light: colors.lightRed,
      contrastText: colors.white,
    },
    secondary: {
      main: colors.secondaryText,
      contrastText: colors.primaryText,
    },
    background: {
      default: colors.lightBackground,
      paper: colors.white,
    },
    text: {
      primary: colors.primaryText,
      secondary: colors.secondaryText,
    },
    error: {
      main: colors.themeRed,
    },
  },
  typography: {
    fontFamily: '"Manrope", "Roboto", "Helvetica", "Arial", sans-serif',
    
    // Major Headers (e.g., "热门推荐", "消息")
    h1: {
      fontFamily: '"Manrope", sans-serif',
      fontWeight: 800, // ExtraBold
      fontSize: '24px',
      color: colors.primaryText,
    },
    h2: {
      fontFamily: '"Manrope", sans-serif',
      fontWeight: 800, // ExtraBold
      fontSize: '20px',
      color: colors.primaryText,
    },
    
    // Card/Item Titles (e.g., Product Names)
    h3: {
      fontFamily: '"Manrope", sans-serif',
      fontWeight: 600, // SemiBold
      fontSize: '16px',
      color: colors.primaryText,
    },
    
    // Body & Descriptions
    body1: {
      fontFamily: '"Manrope", sans-serif',
      fontWeight: 400, // Regular
      fontSize: '14px',
      color: colors.primaryText,
    },
    body2: {
      fontFamily: '"Manrope", sans-serif',
      fontWeight: 400, // Regular
      fontSize: '12px',
      color: colors.secondaryText,
    },
    
    // Buttons & Tabs
    button: {
      fontFamily: '"Manrope", sans-serif',
      fontWeight: 600, // SemiBold
      fontSize: '14px',
      textTransform: 'none', // Prevent uppercase transformation
    },
    
    // Caption text
    caption: {
      fontFamily: '"Manrope", sans-serif',
      fontWeight: 400, // Regular
      fontSize: '12px',
      color: colors.secondaryText,
    },
  },
  components: {
    // Customize MUI components to match design system
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: '8px',
          padding: '12px 24px',
          fontWeight: 600,
          fontSize: '14px',
          textTransform: 'none',
        },
        contained: {
          backgroundColor: colors.themeRed,
          color: colors.white,
          boxShadow: 'none',
          '&:hover': {
            backgroundColor: '#B91C1C', // Darker red on hover
            boxShadow: 'none',
          },
        },
        outlined: {
          borderColor: colors.themeRed,
          color: colors.themeRed,
          '&:hover': {
            backgroundColor: colors.lightRed,
            borderColor: colors.themeRed,
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: '12px',
          boxShadow: '0 2px 8px rgba(0, 0, 0, 0.1)',
          backgroundColor: colors.white,
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: '8px',
            backgroundColor: colors.white,
            '& fieldset': {
              borderColor: '#E5E7EB',
            },
            '&:hover fieldset': {
              borderColor: colors.themeRed,
            },
            '&.Mui-focused fieldset': {
              borderColor: colors.themeRed,
            },
          },
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: colors.white,
          color: colors.primaryText,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          backgroundColor: colors.white,
          borderRight: '1px solid #E5E7EB',
        },
      },
    },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          borderRadius: '8px',
          margin: '4px 8px',
          '&.Mui-selected': {
            backgroundColor: colors.lightRed,
            color: colors.themeRed,
            '&:hover': {
              backgroundColor: colors.lightRed,
            },
          },
          '&:hover': {
            backgroundColor: '#F3F4F6',
          },
        },
      },
    },
    MuiTableHead: {
      styleOverrides: {
        root: {
          backgroundColor: colors.lightBackground,
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          fontWeight: 600,
          color: colors.primaryText,
        },
      },
    },
  },
  spacing: 8, // Default spacing unit (8px)
});

export default theme;
