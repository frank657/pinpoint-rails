import react from '@vitejs/plugin-react'
import inertia from '@inertiajs/vite'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    tailwindcss(),
    RubyPlugin(),
    inertia(),
    react(),
  ],
  // Dev only: the app is served from app/admin/landing on *.lvh.me, but Vite serves modules
  // from localhost:<port> — a cross-origin request. Allow the lvh.me origins so the browser
  // doesn't block the module scripts (which would leave a blank page). See docs/decisions/0006.
  server: {
    cors: { origin: /^https?:\/\/([a-z0-9-]+\.)?lvh\.me(:\d+)?$/ },
    allowedHosts: ['.lvh.me'],
  },
})
