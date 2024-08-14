# frozen_string_literal: true

module Api
  module V1
    # Appointment controller
    class AppointmentsController < ApiController
      before_action :authenticate_user!
      before_action :set_appointment, only: %i[show update]
      before_action :set_services_list, only: %i[create update]

      def index
        @appointments = Appointment.where('customer_id = ? OR seller_id = ?', current_user.id, current_user.id)
        return render_success('Appointment(s) founded.', @appointments, :ok) unless @appointments.empty?

        render_error('Appointment(s) not founded.', :not_found)
      end

      def show
        render_success('Appointment founded.', @appointment, :ok)
      end

      def create
        @appointment = Appointment.new(appointment_params)
        @appointment.customer = current_user
        @appointment.seller = Service.find(@services.first).user
        if @appointment.save
          create_appointment_service_and_price(services: @services)
          render_success('Appointment(s) created.', @appointment, :created)
        else
          render_error("Error. #{@appointment.errors.messages}", :unprocessable_entity)
        end
      end

      def update
        @old_start_date = @appointment.start_date
        @old_end_date = @appointment.end_date
        if authorized_to_update?
          return handle_successful_update if @appointment.update(update_params)

          render_error("Error. #{@appointment.errors.messages}", :unprocessable_entity)
        else
          render_error("Error. #{unauthorized_error_message}", :unprocessable_entity)
        end
      end

      private

      def appointment_params
        params.require(:appointment).permit(:start_date, :end_date, :comment, :status, :seller_id)
      end

      def appointment_params_seller
        params.require(:appointment).permit(:start_date, :end_date, :status, :status, :seller_comment)
      end

      def set_appointment
        @appointment = Appointment.find_by(id: params[:id])
        return if @appointment

        render_error("Appointment #{params[:id]} could not be found.", :not_found)
      end

      def set_services_list
        @services = params[:appointment_services]
      end

      def create_appointment_service_and_price(params = {})
        @services_list = params[:services]
        @services_list.each do |id|
          AppointmentService.where(appointment: @appointment, service: Service.find(id)).destroy_all
          AppointmentService.create(appointment: @appointment, service: Service.find(id))
        end
      end

      def authorized_to_update?
        @appointment.status == 'hold' && (@appointment.customer == current_user || @appointment.seller == current_user)
      end

      def update_params
        @appointment.seller == current_user ? appointment_params_seller : appointment_params
      end

      def handle_successful_update
        create_appointment_service_and_price(services: @services) unless @services.nil?
        render_success('Appointment(s) updated.', @appointment, :ok)
      end

      def unauthorized_error_message
        "You can't modify this appointment,
        because you're not the creator of this appointment,
        or the appointment status is not hold."
      end
    end
  end
end
