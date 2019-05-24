# frozen_string_literal: true

require 'sidekiq_unique_jobs/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  get '/health-check', to: 'health_checks#show'

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
  end

  resources :bonuses

  concern :visible do
    post :update_visibility, on: :member
  end

  concern :labelable do
    post :update_labels, on: :member
  end

  concern :commentable do
    post :create_comment, on: :member
  end

  resources :markets, concerns: %i[visible labelable]
  resources :customers, only: %i[index show], concerns: :labelable do
    member do
      get :account_management
      get :activity
      get :bonuses
      get :notes
      get :betting_limits
      get :deposit_limit
      get :bets
      get :transactions
      get :impersonate
      post :update_promotional_subscription
      patch :update_status
      post :reset_password_to_default
      post :update_labels
      patch :update_personal_information
      patch :update_contact_information
      patch :update_lock
      post :upload_documents
      patch :account_update
      scope '/documents' do
        root to: 'customers#documents', as: :documents
        get '/:document_type',
            to: 'customers#documents_history',
            as: :documents_history
      end
    end
  end

  resources :customers, module: :customers, only: [] do
    resources :entries, only: :index
  end

  resources :customers, only: [], module: :customers do
    resource :statistics, only: :show, path: 'stats'
  end

  resources :customer_bonuses, only: %i[create show destroy]

  resources :betting_limits, only: %i[create update]

  resources :deposit_limits, only: %i[create update destroy]

  post '/customer_attachment_upload',
       to: 'api_upload#customer_attachment_upload'

  resources :customer_notes, only: :create

  resources :labels, only: %i[index new edit create update destroy]

  resources :entry_requests, only: %i[index show create]
  resources :entries, only: :show
  resources :transactions, only: %i[index]
  resources :titles, only: %i[index create]
  resources :event_scopes, only: %i[index show create]

  resources :bets, only: %i[index show]

  resources :currencies, only: %i[index new edit create update]

  resources :verification_documents, concerns: :commentable,
                                     only:        %i[index show],
                                     path:       :documents,
                                     controller: :documents do
    get :status, on: :member
  end

  resource :dashboard, only: :index

  get '/dashboard', to: 'dashboards#index'

  resources :activities, only: %i[index show]

  resources :events, only: %i[index show update],
                     concerns: %i[visible labelable] do
    resources :markets, only: :update
  end

  resources :market_templates, only: %i[index update]

  resources :withdrawals, only: :index do
    member do
      post :confirm
      post :reject
    end
  end

  namespace :redirect do
    resources :deposits, only: [] do
      collection do
        get :initiate
        get :success
        get :error
        get :pending
        get :back
        post :webhook
      end
    end
  end

  namespace :payments do
    get '/', to: 'payments#deposit'

    resources :wirecard, only: [] do
      collection do
        post :notification
      end
    end

    resources :safe_charge, only: [] do
      collection do
        get :notification
      end
    end
  end

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  post '/graphql', to: 'graphql#execute'

  root 'dashboards#index'
end
