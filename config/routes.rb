Rails.application.routes.draw do
  require 'sidekiq/web'
  get 'articles/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :articles, only: [:index]
  post 'scrapping', to: 'articles#scrapping'

  mount Sidekiq::Web => '/sidekiq'
end
