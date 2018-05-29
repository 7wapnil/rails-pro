Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
  end

  namespace :backoffice do
    resources :customers, only: %i[index show]

    resource :dashboard, only: :show

    resources :labels, only: %i[index show]

    root 'dashboards#show'
  end

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  devise_for :customers, controllers: {
    registrations: 'customers/registrations'
  }

  post '/graphql', to: 'graphql#execute'

  resource :dashboard, only: :show

  root 'dashboards#show'
end
