require 'sidekiq/web'

Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
  end

  namespace :backoffice do
    resources :customers, only: %i[index show] do
      member do
        get :activity
        get :notes
        post :update_labels
      end
    end

    resources :customer_notes, only: :create

    resource :dashboard, only: :show

    resources :labels, only: %i[index new edit create update destroy]

    resources :entry_requests, only: %i[index show create]

    root 'dashboards#show'
  end

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  devise_for :customers, controllers: {
    registrations: 'customers/registrations'
  }

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  post '/graphql', to: 'graphql#execute'

  resource :dashboard, only: :show

  root 'dashboards#show'
end
