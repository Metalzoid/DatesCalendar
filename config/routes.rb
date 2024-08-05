Rails.application.routes.draw do
  mount Avo::Engine, at: Avo.configuration.root_path

  require 'sidekiq/web'

  root 'adminsession#avo'

  devise_for :users,
    path: 'api/v1/',
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
    defaults: {
      format: :json
    }

  devise_scope :user do
    get 'api/v1/confirmation_success', to: 'users/confirmations#success', as: :confirmation_success
  end

  namespace :api do
    namespace :v1 do
      defaults format: :json do
        resources :appointments, only: %i[index show create update]
        resources :availabilities, only: %i[index create update destroy]
        get '/sellers', to: 'availabilities#index_sellers'
        resources :services, only: %i[index create update destroy]
      end
    end
  end

  devise_for :admins, path: 'api/v1/', controllers: {
    sessions: 'admins/sessions'
  }, skip: :registration

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
