# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  skip_before_action :verify_authenticity_token

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[firstname lastname company role phone_number avatar])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[firstname lastname company role phone_number avatar])
  end
end
