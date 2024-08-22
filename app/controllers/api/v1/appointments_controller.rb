# frozen_string_literal: true
module Api
  module V1
    # Appointment controller
    class AppointmentsController < ApiController
      before_action :authenticate_user!
      before_action :set_appointment, only: %i[show update]
      before_action :set_services_list, only: %i[create update]

      # @summary Returns the list of Appointment.
      # @response Appointments founded.(200) [Hash] {message: String, data: Hash}
      # @response Appointments not founded.(404) [Hash] {message: String}
      # @response You need to be the seller or the customer or Admin to perform this action.(403) [Hash] {message: String}
      # @tags appointments
      # @auth [bearer_jwt]
      def index
        @appointments = Appointment.where('customer_id = ? OR seller_id = ?', current_user.id, current_user.id)
        return render_success('Appointment(s) founded.', @appointments, :ok) unless @appointments.empty?

        render_error('Appointment(s) not founded.', :not_found)
      end

      # @summary Returns an Appointment.
      # @response Appointment founded.(200) [Hash] {message: String, data: Hash}
      # @response Appointment {{id}} could not be found.(404) [Hash] {message: String}
      # @response You need to be the seller or the customer or Admin to perform this action.(403) [Hash] {message: String}
      # @tags appointments
      # @auth [bearer_jwt]
      def show
        return if authorization

        render_success('Appointment founded.', @appointment, :ok)
      end

      # @summary Create an Appointment.
      # @response You need to be the seller or the customer or Admin to perform this action.(403) [Hash] {message: String}
      # - end_date it's autocalculated by services list by default.
      # -Optional: End_date can be overrided.
      # @request_body The Appointment to be created [Hash] {appointment: {start_date: String, end_date: String, comment: String}, appointment_services: Integer }
      # @request_body_example A complete availability. [Hash] {appointment: {start_date: '14/07/2024 10:00', comment: 'For my son.'}, appointment_services: [1, 2]}
      # @response You need to be the seller or the customer or Admin to perform this action.(403) [Hash] {message: String}
      # @response Appointment created.(201) [Hash] {message: String, data: Hash}
      # @response Can't create appointment.(422) [Hash] {message: String}
      # @tags appointments
      # @auth [bearer_jwt]
      def create
        @appointment = Appointment.new(appointment_params)
        calculate_end_date unless params[:appointment][:end_date]
        @appointment.customer = current_user
        @appointment.seller = Service.find(@services.first).user
        if @appointment.save
          create_appointment_service_and_price(services: @services)
          @appointment.update_price
          render_success('Appointment created.', @appointment, :created)
        else
          render_error("Can't create appointment #{@appointment.errors.messages}", :unprocessable_entity)
        end
      end

      def update
        if authorized_to_update?
          return handle_successful_update if @appointment.update(update_params)

          render_error("Error. #{@appointment.errors.messages}", :unprocessable_entity)
        else
          render_error("Error. #{unauthorized_error_message}", :unprocessable_entity)
        end
      end

      private

      def calculate_end_date
        time = 0
        @services.each do |id|
          time += Service.find(id).time
        end
        @appointment.end_date = @appointment.start_date.to_datetime + time.minutes
      end

      def authorization
        return if [@appointment.seller_id, @appointment.customer_id].include?(current_user.id) if current_user
        return if [@appointment.seller.admin_id, @appointment.customer.admin_id].include?(current_admin.id) if current_admin

        render_error("You need to be the seller or the customer or Admin to perform this action.", :unauthorized)
      end

      def appointment_params
        params.require(:appointment).permit(:start_date, :end_date, :comment, :seller_id)
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
          @appointment.appointment_services.destroy_all
          AppointmentService.create(appointment: @appointment, service: Service.find(id))
        end
      end

      def authorized_to_update?
        if @appointment.status != 'hold' && (update_params[:start_date] || update_params[:end_date])
          return false
        elsif @appointment.status == 'hold' && @appointment.customer == current_user
          return true
        elsif @appointment.seller == current_user || @appointment.seller.admin == current_admin
          return true
        else
          return false
        end
      end

      def update_params
        @appointment.seller == current_user ? appointment_params_seller : appointment_params
      end

      def handle_successful_update
        create_appointment_service_and_price(services: @services) unless @services.nil?
        render_success('Appointment(s) updated.', @appointment, :ok)
      end

      def unauthorized_error_message
        "You can't modify this appointment, because you're not the creator of this appointment, the appointment status is not hold or you want modifying date after accepted status."
      end
    end
  end
end
