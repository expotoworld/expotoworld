import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const region = env.VITE_REGION || 'global';
  
  return {
    plugins: [react()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
        '@components': path.resolve(__dirname, './src/components'),
        '@pages': path.resolve(__dirname, './src/pages'),
        '@locales': path.resolve(__dirname, './src/locales'),
        '@assets': path.resolve(__dirname, './src/assets'),
      },
    },
    define: {
      'import.meta.env.VITE_REGION': JSON.stringify(region),
      'import.meta.env.VITE_ICP_NUMBER': JSON.stringify(env.VITE_ICP_NUMBER || ''),
      'import.meta.env.VITE_PSB_NUMBER': JSON.stringify(env.VITE_PSB_NUMBER || ''),
    },
    server: {
      port: 5175,
    },
    build: {
      outDir: region === 'china' ? 'dist/china' : 'dist/global',
      sourcemap: true,
      rollupOptions: {
        output: {
          manualChunks: {
            'vendor-react': ['react', 'react-dom', 'react-router-dom'],
            'vendor-i18n': ['i18next', 'react-i18next'],
          },
        },
      },
    },
  };
});
