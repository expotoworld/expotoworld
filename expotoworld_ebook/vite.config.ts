import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      // Route ebook-service traffic explicitly to 8084 in dev
      '/api/ebook': {
        target: 'http://localhost:8084',
        changeOrigin: true,
      },
      // Fallback for other /api calls (catalog, etc.)
      '/api': {
        target: process.env.VITE_API_BASE || 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})

