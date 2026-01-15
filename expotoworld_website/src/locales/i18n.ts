/**
 * EXPO to WORLD Website - i18n Configuration
 * Supports English (en) and Chinese (zh) with region-aware defaults
 */

import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

import en from './en.json';
import zh from './zh.json';

export const resources = {
  en: { translation: en },
  zh: { translation: zh },
} as const;

export const supportedLanguages = [
  { code: 'en', name: 'English', nativeName: 'English' },
  { code: 'zh', name: 'Chinese', nativeName: '中文' },
] as const;

// Get default language based on region
const getDefaultLanguage = (): string => {
  const region = import.meta.env.VITE_REGION;
  return region === 'china' ? 'zh' : 'en';
};

// For China builds, prioritize region default over browser language
const getDetectionOrder = (): string[] => {
  const region = import.meta.env.VITE_REGION;
  if (region === 'china') {
    // For China, only check localStorage (for user's explicit choice)
    // Otherwise default to Chinese
    return ['localStorage'];
  }
  return ['localStorage', 'navigator', 'htmlTag'];
};

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources,
    lng: getDefaultLanguage(), // Set initial language based on region
    fallbackLng: getDefaultLanguage(),
    supportedLngs: supportedLanguages.map(lang => lang.code),
    interpolation: {
      escapeValue: false, // React already escapes
    },
    detection: {
      order: getDetectionOrder(),
      caches: ['localStorage'],
      lookupLocalStorage: 'etw_website_language',
    },
  });

export default i18n;
