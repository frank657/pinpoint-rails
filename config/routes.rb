Rails.application.routes.draw do
  # Health check (reachable on every host).
  get "up" => "rails/health#show", as: :rails_health_check

  # Aliyun VOD webhook — signature-verified, server-to-server (no session/CSRF). Aliyun posts
  # to AppConfig.host_backend, which is a dedicated api.* host (not the app subdomain), so this
  # route lives OUTSIDE the subdomain constraints to be reachable on any host.
  post "webhooks/aliyun/vod", to: "webhooks/aliyun/vod#verify"

  # In development, redirect 127.0.0.1 → localhost so the browser shares an IP with the
  # Vite dev server. (Subdomain dev uses *.lvh.me, which already resolves to 127.0.0.1.)
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end

  # app.<domain> — the authenticated user product (Inertia + React).
  constraints(SubdomainConstraint.app) do
    draw(:app)
  end

  # admin.<domain> — the admin panel (Inertia + React, admin-only).
  constraints(SubdomainConstraint.admin) do
    draw(:admin)
  end

  # apex + www — marketing / landing (public).
  constraints(SubdomainConstraint.apex) do
    draw(:landing)
  end
end
