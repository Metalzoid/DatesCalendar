# Controller for API USE RENDER JSON ##
class ApiController < ApplicationController::API
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[firstname lastname entreprise])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[firstname lastname entreprise])
  end
end
