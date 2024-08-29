# frozen_string_literal: true

module Admins
  class AdminsPagesController < ApplicationController
    before_action :authorize_data_admin, only: %i[appointments availabilities services service_destroy availability_destroy]
    before_action :set_users, only: %i[index users appointments availabilities services]
    def index
      @availabilities = @users.flat_map(&:availabilities)
      @appointments = @users.flat_map(&:appointments)
      @services = @users.flat_map(&:services)
      @users_charts = User.group_by_day(current_admin)
      @services_charts = Service.group_by_day(current_admin)
      @availabilities_charts = Availability.group_by_day(current_admin)
      @appointments_charts = Appointment.group_by_day(current_admin)
    end

    def users
    end

    def appointments
      @users = @users.select { |user| user.appointments.any? }
      @appointments = current_admin.users.flat_map(&:appointments)

      if params[:user_id].present? && @appointments.any?
        @appointments = Appointment.where(customer_id: params[:user_id]).or(Appointment.where(seller_id: params[:user_id]))
        respond_to do |format|
          format.html
          format.text { render partial: "admins/admins_pages/appointments_infos", locals: { appointments: @appointments }, formats: [:html] }
        end
      end
    end

    def appointment_destroy
      @appointment = Appointment.find(params[:id])
      redirect_to admins_appointments_path if @appointment.destroy
    end

    def availabilities
      @users = @users.select { |user| user.availabilities.any? }
      @availabilities = @users.flat_map(&:availabilities)

      if params[:user_id].present? && @availabilities.any?
        @availabilities = Availability.where(user_id: params[:user_id])
        respond_to do |format|
          format.html
          format.text { render partial: "admins/admins_pages/availabilities_infos", locals: { availabilities: @availabilities }, formats: [:html] }
        end
      end
    end

    def availability_destroy
      @availability = Availability.find(params[:id])
      redirect_to admins_availabilities_path if @availability.destroy
    end

    def services
      @users = @users.select { |user| user.services.any? }
      @services = @users.flat_map(&:services)
      if params[:user_id].present? && @services.any?
        @services = Service.where(user_id: params[:user_id])
        respond_to do |format|
          format.html
          format.text { render partial: "admins/admins_pages/services_infos", locals: { services: @services }, formats: [:html] }
        end
      end
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

  end
end
