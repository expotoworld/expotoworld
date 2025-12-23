/**
 * EXPO to WORLD Admin Panel - Typography System
 * Based on Designer Agent.md and App Design & Brand Guidelines.md
 */

export const fontFamily = {
  primary: '"Manrope", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
  mono: '"JetBrains Mono", "SF Mono", Consolas, "Liberation Mono", Menlo, monospace',
  chinese: '"Source Han Sans SC", "Noto Sans SC", "PingFang SC", "Microsoft YaHei", sans-serif',
};

export const fontWeight = {
  regular: 400,
  medium: 500,
  semibold: 600,
  bold: 700,
  extrabold: 800,
};

export const typography = {
  // Display - Hero headlines
  display: {
    fontFamily: fontFamily.primary,
    fontSize: '3rem', // 48px
    fontWeight: fontWeight.bold,
    lineHeight: 1.1,
    letterSpacing: '-0.03em',
  },
  
  // H1 - Page titles
  h1: {
    fontFamily: fontFamily.primary,
    fontSize: '1.75rem', // 28px
    fontWeight: fontWeight.bold,
    lineHeight: 1.2,
    letterSpacing: '-0.02em',
  },
  
  // H2 - Section headers
  h2: {
    fontFamily: fontFamily.primary,
    fontSize: '1.375rem', // 22px
    fontWeight: fontWeight.semibold,
    lineHeight: 1.3,
    letterSpacing: '-0.01em',
  },
  
  // H3 - Card titles, subsections
  h3: {
    fontFamily: fontFamily.primary,
    fontSize: '1.125rem', // 18px
    fontWeight: fontWeight.semibold,
    lineHeight: 1.4,
    letterSpacing: '0',
  },
  
  // Body - General content (14px)
  body: {
    fontFamily: fontFamily.primary,
    fontSize: '0.875rem', // 14px
    fontWeight: fontWeight.regular,
    lineHeight: 1.6,
    letterSpacing: '0',
  },
  
  // Body Small - Table content, metadata (12px)
  bodySmall: {
    fontFamily: fontFamily.primary,
    fontSize: '0.75rem', // 12px
    fontWeight: fontWeight.regular,
    lineHeight: 1.5,
    letterSpacing: '0',
  },
  
  // Caption - Labels, timestamps (11px)
  caption: {
    fontFamily: fontFamily.primary,
    fontSize: '0.6875rem', // 11px
    fontWeight: fontWeight.regular,
    lineHeight: 1.4,
    letterSpacing: '0.02em',
  },
  
  // Mono - Code, IDs, technical data (13px)
  mono: {
    fontFamily: fontFamily.mono,
    fontSize: '0.8125rem', // 13px
    fontWeight: fontWeight.regular,
    lineHeight: 1.5,
    letterSpacing: '0',
  },
  
  // Button text
  button: {
    fontFamily: fontFamily.primary,
    fontSize: '0.875rem', // 14px
    fontWeight: fontWeight.semibold,
    lineHeight: 1.4,
    letterSpacing: '0.01em',
    textTransform: 'none' as const,
  },
  
  // Overline - Section labels
  overline: {
    fontFamily: fontFamily.primary,
    fontSize: '0.6875rem', // 11px
    fontWeight: fontWeight.semibold,
    lineHeight: 1.4,
    letterSpacing: '0.1em',
    textTransform: 'uppercase' as const,
  },
};
