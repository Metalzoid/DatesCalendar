# frozen_string_literal: true

module Admins
  # AdminPages Controller
  class AdminsPagesController < ApplicationController
    def index
      @users = current_admin.users
      @availabilities = @users.flat_map(&:availabilities)
      @appointments = @users.flat_map(&:appointments)
      @services = @users.flat_map(&:services)
      @users_charts = User.group_by_day(current_admin)
      @services_charts = Service.group_by_day(current_admin)
      @availabilities_charts = Availability.group_by_day(current_admin)
      @appointments_charts = Appointment.group_by_day(current_admin)
    end
  end
end
