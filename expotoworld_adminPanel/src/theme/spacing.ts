/**
 * EXPO to WORLD Admin Panel - Spacing System
 * Based on 4px base unit
 */

// Base spacing unit: 4px
const BASE = 4;

export const spacing = {
  /** 4px */
  xs: BASE,
  /** 8px */
  sm: BASE * 2,
  /** 12px */
  md: BASE * 3,
  /** 16px */
  lg: BASE * 4,
  /** 20px */
  xl: BASE * 5,
  /** 24px */
  '2xl': BASE * 6,
  /** 32px */
  '3xl': BASE * 8,
  /** 40px */
  '4xl': BASE * 10,
  /** 48px */
  '5xl': BASE * 12,
  /** 64px */
  '6xl': BASE * 16,
};

// Component-specific spacing
export const componentSpacing = {
  // Sidebar
  sidebarWidth: 260,
  sidebarCollapsedWidth: 72,
  
  // Header
  headerHeight: 64,
  
  // Data tables
  tableRowHeight: 48,
  tableDenseRowHeight: 40,
  
  // Cards
  cardPadding: spacing.lg,
  cardGap: spacing.lg,
  
  // Page layout
  pageHeaderHeight: 64,
  pagePadding: spacing['2xl'],
  contentMaxWidth: 1440,
  
  // Form elements
  inputHeight: 40,
  buttonHeight: 40,
  buttonHeightSmall: 32,
  
  // Section gaps
  sectionGap: spacing['3xl'],
};

// Border radius
export const borderRadius = {
  /** 4px - Status badges */
  xs: 4,
  /** 6px - Inputs */
  sm: 6,
  /** 8px - Buttons, cards */
  md: 8,
  /** 12px - Large containers */
  lg: 12,
  /** 16px - Modal dialogs */
  xl: 16,
  /** Full circle */
  full: 9999,
};

// Z-index layers
export const zIndex = {
  drawer: 1200,
  modal: 1300,
  snackbar: 1400,
  tooltip: 1500,
};
