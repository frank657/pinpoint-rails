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
  // Dev only: the app is served from app/admin/landing on *.lvh.me (see docs/decisions/0006),
  // but Vite serves modules from localhost:<port> — a cross-origin request. Allow the lvh.me
  // origins AND plain localhost/127.0.0.1 (any port) so the browser doesn't block the module
  // scripts (which would leave a blank page) regardless of which host you browse from.
  server: {
    cors: { origin: /^https?:\/\/(([a-z0-9-]+\.)?lvh\.me|localhost|127\.0\.0\.1)(:\d+)?$/ },
    allowedHosts: ['.lvh.me', 'localhost', '127.0.0.1'],
  },
  // Force a single React instance. Without dedupe, Vite's dep optimizer can pre-bundle
  // react and react-dom into separate passes, yielding two React copies — the internal
  // dispatcher ends up null and any hook (e.g. Inertia's <Head>) throws "Invalid hook call".
  resolve: {
    dedupe: ['react', 'react-dom'],
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-dom/client', 'react/jsx-dev-runtime', '@inertiajs/react'],
  },
})
