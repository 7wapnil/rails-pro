require 'sidekiq/web'

Rails.application.routes.draw do
  get '/health-check', to: 'health_checks#show'

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
  end

  namespace :backoffice, path: '' do
    constraints subdomain: 'backend' do
      resources :bonuses

  resources :customers, only: %i[index show] do
    member do
      get :account_management
      get :activity
      get :notes
      post :update_labels
    end
  end

  resources :customer_notes, only: :create

  resources :labels, only: %i[index new edit create update destroy]

      resources :currencies, only: %i[index new edit create update]
  resources :entry_requests, only: %i[index show create]

      resource :dashboard, only: :show

      resources :activities, only: %i[index show]
  resource :dashboard, only: :show

      root 'dashboards#show'
    end
  end

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  post '/graphql', to: 'graphql#execute'

  root 'dashboards#show'
end
