import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // 5173 が使用中でも、別ポート（5174 など）へ勝手に逃げず、エラーで止まる。
    // 画面は必ず 5173 で動かす（CLAUDE.md のポートのルール）。
    strictPort: true,
    // /api への通信を、バックエンド（Spring Boot）へ転送する。
    // ブラウザからは同じ場所（5173）への通信に見えるので、CORS の設定は要らない。
    proxy: {
      '/api': 'http://localhost:8080',
    },
  },
})
