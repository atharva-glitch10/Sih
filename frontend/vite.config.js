import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// Default to FastAPI port 8000, fallback to Express port 3000 if configured
const BACKEND_PORT = process.env.VITE_BACKEND_PORT || '8000';
const BACKEND_TARGET = `http://127.0.0.1:${BACKEND_PORT}`;

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: BACKEND_TARGET,
        changeOrigin: true,
        secure: false,
      },
      '/data': {
        target: BACKEND_TARGET,
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
