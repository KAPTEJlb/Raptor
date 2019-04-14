Rails.application.routes.draw do
  devise_for :users
  devise_for :models
  root to: 'homes#index'

  resource :homes
  require 'sidekiq/web'
  require 'sidekiq-status/web'
  mount Sidekiq::Web => '/sidekiq'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
