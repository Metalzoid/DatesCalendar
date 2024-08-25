# frozen_string_literal: true

module Admins
  class AdminsPagesController < ApplicationController
    def index
      @users = current_admin.users
      @availabilities = @users.map(&:availabilities).flatten
      @appointments = @users.map(&:appointments).flatten
      @services = @users.map(&:services).flatten
      respond_to do |format|
        format.html { render "admins_pages/index" }
      end
    end
  end
end
