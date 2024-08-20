# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'
  api_version = Rails.configuration.x.api.version


  root to: 'pages#index'
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

  get "api/#{api_version}/user_search", to: 'api#user_search'
  namespace :api do
    namespace :v1 do

      defaults format: :json do
        get 'unavailabilities', to: 'availabilities#index'
        resources :appointments, only: %i[index show create update]
        resources :availabilities, only: %i[index create update destroy]
        resources :services, only: %i[index create update destroy]
      end
    end
  end

  devise_for :admins, path: "api/#{api_version}/admin", controllers: {
    sessions: 'admins/sessions',
    registrations: 'admins/registrations',
    omniauth_callbacks: 'admins/omniauth_callbacks'
  }, path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  }

  authenticate :admin do
    mount OasRails::Engine, at: '/docs'
  end
  
  get 'admin', to: 'admins/admins_pages#index', as: :admin_index

  get 'up', to: 'rails/health#show', as: :rails_health_check
end
