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
      post :update_customer_status
      post :update_labels
      post :upload_documents
      scope '/documents' do
        root to: 'customers#documents', as: :documents
        get '/:document_type',
            to: 'customers#documents_history',
            as: :documents_history
      end
    end
  end

  post '/customer_attachment_upload',
       to: 'api_upload#customer_attachment_upload'

  resources :customer_notes, only: :create

  resources :labels, only: %i[index new edit create update destroy]

  resources :entry_requests, only: %i[index show create]

  resources :bets, only: :index

  resources :currencies, only: %i[index new edit create update]

  scope 'documents' do
    root to: 'documents#index', as: :documents
    get '/:id', to: 'documents#status', as: :document_status
  end

  resource :dashboard, only: :show

  resources :activities, only: %i[index show]

  resources :events, only: %i[index show]

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  post '/graphql', to: 'graphql#execute'

  root 'dashboards#show'
end
