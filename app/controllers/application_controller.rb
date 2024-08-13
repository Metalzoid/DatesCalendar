# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  skip_before_action :verify_authenticity_token

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[firstname lastname company role])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[firstname lastname company role])
  end

  def after_sign_in_path_for(resource)
    if resource.persisted?
      admin_index_path
    else
      super(resource)
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    if resource_or_scope == :admin
      new_admin_session_path
    else
      super(resource_or_scope)
    end
  end
end
