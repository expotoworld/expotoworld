/**
 * EXPO to WORLD Admin Panel - Design System Colors
 * Based on Designer Agent.md and App Design & Brand Guidelines.md
 * 
 * This file defines ALL colors used in the application.
 * ONLY use colors from this file - no hardcoded colors elsewhere.
 */

// ============================================
// PRIMARY BRAND COLORS
// ============================================

/** Theme Red - Primary accent color for CTAs, links, active states */
export const themeRed = '#EE3432';
export const themeRedDark = '#B82025';
export const themeRedDarker = '#7A1619';
export const themeRedLight = '#FF5252';
export const themeRedLightest = '#FCE8E8';

// Red palette aliases
export const red500 = themeRed;
export const red400 = themeRedLight;
export const red600 = themeRedDark;
export const red700 = themeRedDarker;
export const red100 = themeRedLightest;

// ============================================
// SEMANTIC COLOR PALETTE
// ============================================

// Blues
export const blue = '#0066CC';
export const blueDark = '#004B91';
export const blueDarker = '#0F2C4C';
export const teal = '#008080';
export const blueMuted = '#4A6C8C';

// Blue palette aliases
export const blue500 = blue;
export const blue600 = blueDark;
export const blue700 = blueDarker;

// Yellows
export const yellow = '#FFC107';
export const yellowDark = '#F5A623';
export const yellowMuted = '#C5A059';
export const yellowDarker = '#9C7C38';
export const yellowLightest = '#FFF8E1';

// Yellow palette aliases
export const yellow500 = yellow;
export const yellow400 = yellowDark;
export const yellow100 = yellowLightest;

// Greens
export const green = '#107C10';
export const greenDark = '#0A4D0A';
export const greenLight = '#2ECC71';
export const greenMuted = '#8FA395';
export const greenLightest = '#E6F4EA';

// Green palette aliases
export const green500 = green;
export const green400 = greenLight;
export const green600 = greenDark;
export const green100 = greenLightest;

// Neutrals
export const neutralLightest = '#F8F9FA';
export const neutralLight = '#F1F1F1';
export const neutralMid = '#D1D5DB';
export const neutralDark = '#4A4A4A';
export const neutralDarkest = '#121212';

// Neutral palette aliases
export const neutralWhite = '#FFFFFF';
export const neutralBlack = '#000000';
export const neutralGray100 = neutralLightest;
export const neutralGray200 = neutralLight;
export const neutralGray300 = neutralMid;
export const neutralGray400 = '#9CA3AF';
export const neutralGray500 = '#6B7280';
export const neutralGray600 = neutralDark;
export const neutralGray700 = '#374151';
export const neutralGray800 = '#1F2937';
export const neutralGray900 = neutralDarkest;

// Exotic/Accent Colors
export const purple = '#6A1B9A';
export const orange = '#FF5722';
export const cyan = '#00BCD4';
export const purpleDark = '#4A2C58';
export const slate = '#607D8B';

// Exotic palette aliases
export const exoticPurple = purple;
export const exoticCoral = '#FF6B6B';
export const exoticTeal = teal;

// ============================================
// DARK MODE SEMANTIC TOKENS
// ============================================

export const darkMode = {
  backgroundDeep: '#0D0D0D',
  backgroundBase: '#0D0D0D',
  backgroundElevated: '#1A1A1A',
  backgroundPaper: 'rgba(26, 26, 26, 0.8)',  // Semi-transparent for glassmorphism
  backgroundModal: '#1A1A1A',  // Solid background for modals/dialogs
  surface: 'rgba(248, 249, 250, 0.03)',
  surfaceHover: 'rgba(248, 249, 250, 0.06)',
  foreground: '#F5F5F7',
  foregroundMuted: '#A1A1A6',
  foregroundSubtle: '#6E6E73',
  borderDefault: 'rgba(255, 255, 255, 0.08)',
  borderHover: 'rgba(255, 255, 255, 0.12)',
  borderAccent: themeRed,
  accentGlow: 'rgba(238, 52, 50, 0.2)',
  // Glassmorphism specific
  glassBackground: 'rgba(255, 255, 255, 0.05)',
  glassBorder: 'rgba(255, 255, 255, 0.08)',
  cardGradientStart: 'rgba(255, 255, 255, 0.08)',  // 8% white
  cardGradientEnd: 'rgba(255, 255, 255, 0.02)',    // 2% white
};

// ============================================
// LIGHT MODE SEMANTIC TOKENS
// ============================================

export const lightMode = {
  backgroundDeep: '#F5F5F7',
  backgroundBase: '#F5F5F7',
  backgroundElevated: '#FFFFFF',
  backgroundPaper: 'rgba(255, 255, 255, 0.9)',  // Semi-transparent for glassmorphism
  backgroundModal: '#FFFFFF',  // Solid background for modals/dialogs
  surface: 'rgba(18, 18, 18, 0.02)',
  surfaceHover: 'rgba(18, 18, 18, 0.04)',
  foreground: '#1D1D1F',
  foregroundMuted: '#6E6E73',
  foregroundSubtle: '#9CA3AF',
  borderDefault: 'rgba(0, 0, 0, 0.06)',
  borderHover: 'rgba(0, 0, 0, 0.1)',
  borderAccent: themeRed,
  accentGlow: 'rgba(238, 52, 50, 0.12)',
  // Glassmorphism specific
  glassBackground: 'rgba(255, 255, 255, 0.7)',
  glassBorder: 'rgba(0, 0, 0, 0.06)',
  cardGradientStart: 'rgba(255, 255, 255, 0.95)',
  cardGradientEnd: 'rgba(255, 255, 255, 0.85)',
};

// ============================================
// STATUS COLORS
// ============================================

export const statusColors = {
  success: green500,
  successLight: green100,
  warning: yellow500,
  warningLight: yellow100,
  error: themeRed,
  errorLight: red100,
  info: blue500,
  infoLight: '#E0F2FE',
};

// ============================================
// STORE TYPE COLORS (Matching Flutter app)
// ============================================

export const storeTypeColors = {
  mega: blue500,      // Blue for MEGA (B2B)
  market: green500,   // Green for MARKET (B2C)
  toGo: purple,       // Purple for to GO
  xpress: yellow500,  // Yellow for XPRESS
};
