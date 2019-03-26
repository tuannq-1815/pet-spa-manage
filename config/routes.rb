Rails.application.routes.draw do
  get "sessions/new"
  get "/signup", to: "users#new"
  get "/admin", to: "admin/base#home"
  get "/home", to: "static_pages#home"
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  root "static_pages#home"

  resources :users
  namespace :admin do
   resources :comments, only: %i(index destroy)
  end
end