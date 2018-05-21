Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'
  end

  namespace :backoffice do
    devise_for :users

    resource :dashboard, only: :show

    root 'dashboards#show'
  end

  devise_for :customers, controllers: {
    registrations: 'customers/registrations'
  }

  post '/graphql', to: 'graphql#execute'

  resource :dashboard, only: :show

  root 'dashboards#show'
end
