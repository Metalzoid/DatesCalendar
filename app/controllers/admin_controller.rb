class AdminController < ApplicationController
  before_action :authenticate_admin!
  def index
  end

  private

  def authenticate_admin!
    redirect_to new_admin_session_path if current_admin.nil?
  end
end
