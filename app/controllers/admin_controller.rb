class AdminController < ApplicationController
  before_action :authenticate_admin!
  def index
  end

  private

  def authenticate_admin!
    redirect_to new_admin_session_path if current_admin.nil?
    # unless current_admin_user.nil?
    #   raise ActionController::RoutingError.new('You need to be a Admin role to perform this action.') unless current_admin_user.admin?
    # end
  end
end
