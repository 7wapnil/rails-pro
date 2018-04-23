Rails.application.routes.draw do
  resource :dashboard, only: :show

  root 'dashboards#show'
end
