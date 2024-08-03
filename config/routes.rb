Rails.application.routes.draw do
  require 'sidekiq/web'

  devise_for :users,
    path: '',
    path_names: {
      sign_in: 'login',
      sign_out: 'logout',
      registration: 'signup'
    },
    controllers: {
      sessions: 'users/sessions',
      registrations: 'users/registrations',
      confirmations: 'confirmations'
    },
    defaults: {
      format: :json
    }

  defaults format: :json do
    resources :appointments, only: %i[index show create update]
    resources :availabilities, only: %i[index create update destroy]
    get '/vendors', to: 'availabilities#index_vendors'
    resources :services, only: %i[index create update destroy]
  end

  devise_for :admins, path: 'admin', controllers: {
    sessions: 'admins/sessions'
  }

  resources :admin, only: %i[index]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
