Rails.application.routes.draw do
  devise_for :users
  devise_for :models
  root to: 'homes#index'

  resource :homes
  match 'pdf_metadata' => 'homes', via: :get
  match 'download_pdf' => "homes#download_pdf", via: :get
  require 'sidekiq/web'
  require 'sidekiq-status/web'
  mount Sidekiq::Web => '/sidekiq'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
