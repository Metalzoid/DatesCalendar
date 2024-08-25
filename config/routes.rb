# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'
  api_version = Rails.configuration.x.api.version
  if Rails.env.production?
    root to: redirect('/admin')
  else
    root to: redirect('/docs')
  end
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

  mount OasRails::Engine, at: '/docs' unless Rails.env.production?

  get 'admin', to: 'admins/admins_pages#index', as: :admin_index

  get 'up', to: 'rails/health#show', as: :rails_health_check
end
