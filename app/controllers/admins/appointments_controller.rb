# app/controllers/admins/appointments_controller.rb
module Admins
  class AppointmentsController < Admins::AdminsPagesController
    before_action :authorize_data_admin, only: %i[index destroy]
    before_action :set_users, only: %i[index]

    def index
      filter_users_with_appointments
      @appointments = @users.flat_map(&:appointments).sort_by(&:id)
      filter_appointments_by_user_id if params[:user_id].present? && params[:user_id] != 'none'
      respond_to_formats('appointments_infos', appointments: @appointments)
    end

    def destroy
      @appointment = Appointment.find(params[:id])
      if params[:listed].present? && @appointment.destroy
        redirect_to "#{admins_appointments_url}?user_id=#{@appointment.user.id}"
      elsif @appointment.destroy
        redirect_to admins_appointments_path
      end
    end

    private

    def set_users
      @users = current_admin.users
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
