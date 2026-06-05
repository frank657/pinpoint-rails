# Routes for admin.<domain> — the admin panel (admin-only; docs/decisions/0006).
# Controllers live under app/controllers/admin/.
scope module: :admin, as: :admin do
  get "/", to: "dashboard#index", as: :root
  get "dashboard", to: "dashboard#index"

  resources :users, only: %i[index update]
  resources :workspaces, only: %i[index]
  resources :videos, only: %i[index]
end
