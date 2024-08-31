# app/controllers/admins/appointments_controller.rb
module Admins
  class AppointmentsController < ApplicationController
    before_action :authorize_data_admin, only: %i[index destroy]
    before_action :set_users, only: %i[index]

    def index
      filter_users_with_appointments
      @appointments = @users.flat_map(&:appointments)

      return unless params[:user_id].present? && @appointments.any?

      filter_appointments_by_user_id
      respond_to_formats('appointments_infos', appointments: @appointments)
    end

    def destroy
      @appointment = Appointment.find(params[:id])
      redirect_to admins_appointments_path if @appointment.destroy
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

    def filter_appointments_by_user_id
      @appointments = Appointment.where(customer_id: params[:user_id])
                                 .or(Appointment.where(seller_id: params[:user_id]))
    end

    def respond_to_formats(partial_name, locals)
      respond_to do |format|
        format.html
        format.text { render(partial: "admins/appointments/#{partial_name}", locals:, formats: [:html]) }
      end
    end
  end
end
