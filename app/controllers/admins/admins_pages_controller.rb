# frozen_string_literal: true

module Admins
  # AdminPages Controller
  class AdminsPagesController < ApplicationController
    before_action :authorize_data_admin,
                  only: %i[appointments availabilities services service_destroy
                           availability_destroy]
    before_action :set_users,
                  only: %i[index users appointments availabilities services]

    def index
      @availabilities = @users.flat_map(&:availabilities)
      @appointments = @users.flat_map(&:appointments)
      @services = @users.flat_map(&:services)
      @users_charts = User.group_by_day(current_admin)
      @services_charts = Service.group_by_day(current_admin)
      @availabilities_charts = Availability.group_by_day(current_admin)
      @appointments_charts = Appointment.group_by_day(current_admin)
    end

    def users; end

    def appointments
      filter_users_with_appointments
      @appointments = current_admin.users.flat_map(&:appointments)

      return unless params[:user_id].present? && @appointments.any?

      filter_appointments_by_user_id
      respond_to_formats('appointments_infos', appointments: @appointments)
    end

    def appointment_destroy
      @appointment = Appointment.find(params[:id])
      redirect_to admins_appointments_path if @appointment.destroy
    end

    def availabilities
      filter_users_with_availabilities
      @availabilities = @users.flat_map(&:availabilities)

      return unless params[:user_id].present? && @availabilities.any?

      filter_availabilities_by_user_id
      respond_to_formats('availabilities_infos', availabilities: @availabilities)
    end

    def availability_destroy
      @availability = Availability.find(params[:id])
      redirect_to admins_availabilities_path if @availability.destroy
    end

    def services
      filter_users_with_services
      @services = @users.flat_map(&:services)

      return unless params[:user_id].present? && @services.any?

      filter_services_by_user_id
      respond_to_formats('services_infos', services: @services)
    end

    def service_destroy
      @service = Service.find(params[:id])
      redirect_to admins_services_path if @service.destroy
    end

    private

    def set_users
      @users = current_admin.users
    end

    def authorize_data_admin
      return unless params[:user_id].present?

      redirect_to('/401') unless current_admin.users.find_by(id: params[:user_id])
    end

    def filter_users_with_appointments
      @users = @users.select { |user| user.appointments.any? }
    end

    def filter_users_with_availabilities
      @users = @users.select { |user| user.availabilities.any? }
    end

    def filter_users_with_services
      @users = @users.select { |user| user.services.any? }
    end

    def filter_appointments_by_user_id
      @appointments = Appointment.where(customer_id: params[:user_id])
                                 .or(Appointment.where(seller_id: params[:user_id]))
    end

    def filter_availabilities_by_user_id
      @availabilities = Availability.where(user_id: params[:user_id])
    end

    def filter_services_by_user_id
      @services = Service.where(user_id: params[:user_id])
    end

    def respond_to_formats(partial_name, locals)
      respond_to do |format|
        format.html
        format.text { render(partial: "admins/admins_pages/#{partial_name}", locals:, formats: [:html]) }
      end
    end
  end
end
