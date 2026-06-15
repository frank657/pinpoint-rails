# Routes for app.<domain> — the authenticated user product.
# Devise (session-based) lives here so auth happens on the app host (docs/decisions/0006).
devise_for :users, controllers: {
  sessions: "auth/sessions",
  registrations: "auth/registrations",
  passwords: "auth/passwords"
}

# Aliyun VOD webhook (signature-verified, no auth/CSRF). Aliyun posts to the app host
# (AppConfig.host_backend) — see app/lib/ali_vod/config.rb.
post "webhooks/aliyun/vod", to: "webhooks/aliyun/vod#verify"

# Controllers live under app/controllers/app/ (module: :app keeps URLs unprefixed).
scope module: :app, as: :app do
  get "/", to: "dashboard#index", as: :root
  get "dashboard", to: "dashboard#index"

  resources :workspaces, only: %i[index create update destroy]
  post "workspaces/:id/switch", to: "workspaces#switch", as: :switch_workspace

  resources :videos, only: %i[index show create update destroy] do
    get :status, on: :member
  end
  get "search",       to: "search#index"
  get "search/query", to: "search#query"
  post "videos/youtube", to: "videos#create_youtube", as: :youtube_videos

  # Direct-upload flow (ADR 0007): provision → upload to OSS → poll → create Video.
  post "vod/direct_uploads",          to: "vod/direct_uploads#create", as: :vod_direct_uploads
  get  "vod/status/:signed_id",       to: "vod/direct_uploads#status", as: :vod_status

  resources :notes, only: %i[index new create update destroy]
  resources :categories, only: %i[index create update destroy]
  resources :tags, only: %i[index create update destroy] do
    post :merge, on: :member
  end
  resources :segments, only: %i[create update destroy]

  post "progress", to: "progress#upsert"

  resources :positions, only: %i[index show create] do
    post :seed, on: :collection
  end
  resources :techniques, only: %i[create]

  resources :shares, only: %i[create destroy]
  get "s/:token", to: "shares#show", as: :share_view
  post "s/:token/fork", to: "forks#create", as: :share_fork
end
