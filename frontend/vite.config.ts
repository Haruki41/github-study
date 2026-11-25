import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // /api への通信を、バックエンド（Spring Boot）へ転送する。
    // ブラウザからは同じ場所（5173）への通信に見えるので、CORS の設定は要らない。
    proxy: {
      '/api': 'http://localhost:8080',
    },
  },
})
