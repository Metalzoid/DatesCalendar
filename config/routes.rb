# frozen_string_literal: true

Rails.application.routes.draw do
  mount OasRails::Engine, at: '/docs'
  api_version = Rails.configuration.x.api.version

  root to: redirect('/docs')

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

  namespace :api do
    namespace :v1 do
      defaults format: :json do
        get 'user_search', to: 'api#user_search'
        resources :appointments, only: %i[index show create update]
        resources :availabilities, only: %i[index create update destroy]
        resources :services, only: %i[index create update destroy]
      end
    end
  end

  devise_for :admins, path: "admin", controllers: {
    sessions: 'admins/sessions',
    registrations: 'admins/registrations',
    omniauth_callbacks: 'admins/omniauth_callbacks',
    confirmations: 'admins/confirmations'
  }, path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  }

  devise_scope :admin do
    get '/confirmation-success', to: 'admins/confirmations#success', as: 'confirmation_success'
  end

  authenticate :admin do
    namespace :admins, path: 'admin' do
      get '/', to: 'admins_pages#index', as: :index
      get 'users', to: 'admins_pages#users'
      get 'appointments', to: 'admins_pages#appointments'
      get 'availabilities', to: 'admins_pages#availabilities'
      get 'services', to: 'admins_pages#services'
      delete "service/:id", to: "admins_pages#service_destroy", as: :service
      delete "availability/:id", to: "admins_pages#availability_destroy", as: :availability
      delete "appointment/:id", to: "admins_pages#appointment_destroy", as: :appointment
    end
  end

  get 'up', to: 'rails/health#show', as: :rails_health_check
end
