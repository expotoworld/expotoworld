import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';

// Vite configuration for the admin panel SPA
// - Uses React + TS
// - Outputs to `build/` to match the previous CRA structure used by S3/CloudFront

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'build',
  },
  server: {
    port: 3000,
  },
});

