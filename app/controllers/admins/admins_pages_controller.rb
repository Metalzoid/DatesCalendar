# frozen_string_literal: true

module Admins
  class AdminsPagesController < ApplicationController
    before_action :authenticate_admin!
    def index
      @users = current_admin.users
      @availabilities = @users.map(&:availabilities).flatten + @users.map(&:unavailabilities).flatten
      @appointments = @users.map(&:appointments).flatten
      @services = @users.map(&:services).flatten
      respond_to do |format|
        format.html { render "admins_pages/index" }
      end
    end

    private

    def authenticate_admin!
      redirect_to new_admin_session_path unless current_admin
    end
  end
end
