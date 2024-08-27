# frozen_string_literal: true

module Admins
  class AdminsPagesController < ApplicationController
    def index
      @users = current_admin.users
      @availabilities = @users.map(&:availabilities).flatten
      @appointments = @users.map(&:appointments).flatten
      @services = @users.map(&:services).flatten
      @users_charts = User.group_by_day(current_admin)
      @services_charts = Service.group_by_day(current_admin)
      @availabilities_charts = Availability.group_by_day(current_admin)
      @appointments_charts = Appointment.group_by_day(current_admin)

      respond_to do |format|
        format.html { render "admins_pages/index" }
      end
    end

    def users
      @users = current_admin.users
    end

  end
end
