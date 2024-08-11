# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'

  api_version = Rails.configuration.x.api.version

  devise_for :users,
             path: "api/#{api_version}",
             path_names: {
               sign_in: 'login',
               sign_out: 'logout',
               registration: 'signup'
             },
             controllers: {
               sessions: 'users/sessions',
               registrations: 'users/registrations',
               confirmations: 'users/confirmations'
             },
             defaults: { format: :json }

  devise_scope :user do
    get "api/#{api_version}/confirmation_success", to: 'users/confirmations#success', as: :confirmation_success
  end

  root to: redirect("/api/#{api_version}")
  get "/api/#{api_version}/user_search", to: 'api#user_search'

  namespace :api do
    namespace :v1 do
      root to: 'pages#index'
      namespace :admin do
        root to: 'admin_pages#index'
        get '', to: 'admin_pages#index'
      end

      defaults format: :json do
        resources :appointments, only: %i[index show create update]
        resources :availabilities, only: %i[index create update destroy]
        get 'unavailabilities', to: 'availabilities#index'
        resources :services, only: %i[index create update destroy]
      end
    end
  end

  devise_for :admins, path: "api/#{api_version}/admin", controllers: {
    sessions: 'admins/sessions'
  }

  get 'up', to: 'rails/health#show', as: :rails_health_check
end
