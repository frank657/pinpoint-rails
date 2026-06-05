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

  resources :videos, only: %i[index show destroy] do
    get :status, on: :member
    get :summary, on: :member
    post "flashcard", to: "videos#accept_flashcard", on: :member
    post "transcript", to: "transcripts#create", on: :member
  end
  get "search", to: "search#index"
  post "videos/youtube", to: "videos#create_youtube", as: :youtube_videos
  post "videos/upload",  to: "videos/uploads#create", as: :video_uploads

  resources :notes, only: %i[index new create update destroy]
  resources :categories, only: %i[index create update destroy]
  resources :tags, only: %i[index]
  resources :segments, only: %i[create update destroy]

  resources :courses, only: %i[index show create update destroy] do
    resources :chapters, only: %i[create update destroy], module: :courses
    resources :items, only: %i[create update destroy], module: :courses do
      post :reorder, on: :collection
    end
  end
  resources :curriculums, only: %i[index show create update destroy] do
    resources :items, only: %i[create destroy], module: :curriculums do
      post :reorder, on: :collection
    end
  end
  resources :folders, only: %i[index create update destroy]

  post "progress", to: "progress#upsert"

  resources :training_sessions, only: %i[index create destroy]

  resources :positions, only: %i[index show create] do
    post :seed, on: :collection
  end
  resources :techniques, only: %i[create]

  get "review", to: "review#index"
  post "review", to: "review#create", as: :review_cards
  post "review/:id/grade", to: "review#grade", as: :grade_review_card

  resources :shares, only: %i[create destroy]
  get "s/:token", to: "shares#show", as: :share_view
  post "s/:token/fork", to: "forks#create", as: :share_fork
end
