/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_REGION: 'global' | 'china';
  readonly VITE_DEFAULT_LANGUAGE: 'en' | 'zh';
  readonly VITE_SITE_URL: string;
  readonly VITE_ICP_NUMBER: string;
  readonly VITE_PSB_NUMBER: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
