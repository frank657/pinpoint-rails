import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import axios from 'axios'

// Bridge Rails CSRF with Inertia/axios: the server sets an XSRF-TOKEN cookie
// (ApplicationController#set_csrf_cookie); axios reads it and sends it back under the
// header name Rails checks (X-CSRF-Token). See docs/decisions/0001.
axios.defaults.xsrfCookieName = 'XSRF-TOKEN'
axios.defaults.xsrfHeaderName = 'X-CSRF-Token'

void createInertiaApp({
  pages: "../pages",

  setup({ el, App, props }) {
    createRoot(el!).render(<App {...props} />)
  },

  strictMode: true,

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => {
      return { queryStringArrayFormat: "brackets" }
    },
  },
}).catch((error) => {
  // This ensures this entrypoint is only loaded on Inertia pages
  // by checking for the presence of the root element (#app by default).
  // Feel free to remove this `catch` if you don't need it.
  if (document.getElementById("app")) {
    throw error
  } else {
    console.error(
      "Missing root element.\n\n" +
      "If you see this error, it probably means you loaded Inertia.js on non-Inertia pages.\n" +
      'Consider moving <%= vite_typescript_tag "inertia.tsx" %> to the Inertia-specific layout instead.',
    )
  }
})
