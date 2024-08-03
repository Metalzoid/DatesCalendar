# Controller for API USE RENDER JSON ##
class ApiController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ActionController::UnpermittedParameters, with: :handle_errors

  private

  def handle_errors
    render json: { "Unpermitted Parameters": params.to_unsafe_h.except(:controller, :action, :id).keys }, status: :unprocessable_entity
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[firstname lastname entreprise])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[firstname lastname entreprise])
  end
end
