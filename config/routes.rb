require 'sidekiq/web'

Rails.application.routes.draw do
  get '/health-check', to: 'health_checks#show'

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
  end

  resources :bonuses

  resources :customers, only: %i[index show] do
    member do
      get :account_management
      get :activity
      get :notes
      get :documents
      post :update_labels
      post :upload_documents, to: 'customers#upload_documents'
    end
  end

  resources :customer_notes, only: :create

  resources :labels, only: %i[index new edit create update destroy]

  resources :entry_requests, only: %i[index show create]

  resources :currencies, only: %i[index new edit create update]

  resource :dashboard, only: %i[show create]

  resources :activities, only: %i[index show]

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  post '/graphql', to: 'graphql#execute'
  post '/customer_attachment_upload',
       to: 'customer_attachment#customer_attachment_upload'

  root 'dashboards#show'
end
