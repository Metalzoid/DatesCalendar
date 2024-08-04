Rails.application.routes.draw do
  mount Avo::Engine, at: Avo.configuration.root_path

  require 'sidekiq/web'
  
  root 'adminsession#avo'

  devise_for :users,
  path: '',
  path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  },
  defaults: {
    format: :json
  }

  devise_scope :user do
    resources :confirmations, controller: 'users/confirmations', only: [:show, :new, :create], defaults: { format: :html }
    get 'confirmation_success', to: 'users/confirmations#success', as: :confirmation_success
  end

  defaults format: :json do
    resources :appointments, only: %i[index show create update]
    resources :availabilities, only: %i[index create update destroy]
    get '/sellers', to: 'availabilities#index_sellers'
    resources :services, only: %i[index create update destroy]
  end

  devise_for :admins, path: 'admin', controllers: {
    sessions: 'admins/sessions'
  }, skip: :registration

  # resources :admin, only: %i[index]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
