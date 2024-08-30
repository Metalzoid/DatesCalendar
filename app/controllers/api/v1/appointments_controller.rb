# frozen_string_literal: true

module Api
  module V1
    # Appointment controller
    class AppointmentsController < ApiController
      before_action :set_appointment, only: %i[show update]
      before_action :set_services_list, only: %i[create update]

      # @summary Returns the list of Appointments.
      # @response [200] { Hash{message: String, data: Array<Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer }>} }
      # @response [404] { Hash{message: String} }
      # @response [403] { Hash{message: String} }
      # @tags appointments
      # @auth [bearer_jwt]
      def index
        appointments = Appointment.where(customer_id: current_user.id).or(Appointment.where(seller_id: current_user.id))
        serialized_appointments = appointments.map { |appointment| AppointmentSerializer.new(appointment).serializable_hash[:data][:attributes] }
        render_success('Appointments found.', serialized_appointments, :ok)
      rescue ActiveRecord::RecordNotFound
        render_error('Appointments not found.', :not_found)
      end

      # @summary Returns an Appointment.
      # @response [200] { Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer }} }
      # @response [404] { Hash{message: String} }
      # @response [403] { Hash{message: String} }
      # @tags appointments
      # @auth [bearer_jwt]
      def show
        return if authorization

        render_success('Appointment found.', AppointmentSerializer.new(@appointment).serializable_hash[:data][:attributes], :ok)
      end

      # @summary Create an Appointment.
      # @request_body [!Hash{appointment: Hash{start_date: Datetime, end_date: Datetime, comment: String}, appointment_services: Array<Integer>}]
      # @response [201] { Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer}} }
      # @response [403] { Hash{message: String} }
      # @response [422] { Hash{message: String} }
      # @tags appointments
      # @auth [bearer_jwt]
      def create
        return render_error('Appointment_services OR End_date required!', :unprocessable_entity) unless @services || params.dig(:appointment, :end_date)
        return render_error('seller_id required!', :unprocessable_entity) if @services.nil? && params.dig(:appointment, :seller_id).nil?

        @appointment = Appointment.new(appointment_params)
        calculate_end_date unless params.dig(:appointment, :end_date)
        @appointment.customer = current_user
        @appointment.seller = Service.find(@services.first).user if @services
        if @appointment.save
          create_appointment_services if @services
          render_success('Appointment created.', AppointmentSerializer.new(@appointment).serializable_hash[:data][:attributes], :created)
        else
          render_error("Can't create appointment: #{@appointment.errors.full_messages.to_sentence}", :unprocessable_entity)
        end
      end

      # @summary Update an Appointment.
      # @request_body [!Hash{appointment: Hash{start_date: DateTime, end_date: DateTime, status: String, comment: String, seller_comment: String, price: Float}}]
      # @response [200] { Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer}} }
      # @response [401] { Hash{message: String} }
      # @response [403] { Hash{message: String} }
      # @tags appointments
      # @auth [bearer_jwt]
      def update
        return render_error(unauthorized_error_message, :forbidden) unless authorized_to_update?

        if @appointment.update(update_params)
          create_appointment_services if @services
          render_success('Appointment updated.', AppointmentSerializer.new(@appointment).serializable_hash[:data][:attributes], :ok)
        else
          render_error("Error: #{@appointment.errors.full_messages.to_sentence}", :unprocessable_entity)
        end
      end

      private

      def calculate_end_date
        @appointment.end_date = @appointment.start_date.to_datetime + @services.sum { |id| Service.find(id).time }.minutes
      end

      def authorization
        return if user_authorized? || admin_authorized?

        render_error('You need to be the seller, the customer, or an admin to perform this action.', :unauthorized)
      end

      def user_authorized?
        current_user && [@appointment.seller_id, @appointment.customer_id].include?(current_user.id)
      end

      def admin_authorized?
        current_admin && [@appointment.seller.admin_id, @appointment.customer.admin_id].include?(current_admin.id)
      end

      def appointment_params
        params.require(:appointment).permit(:start_date, :end_date, :comment, :seller_id)
      end

      def appointment_params_seller
        params.require(:appointment).permit(:start_date, :end_date, :status, :seller_comment)
      end

      def set_appointment
        @appointment = Appointment.find_by(id: params[:id])
        render_error("Appointment #{params[:id]} could not be found.", :not_found) unless @appointment
      end

      def set_services_list
        @services = params[:appointment_services]
      end

      def create_appointment_services
        @appointment.appointment_services.destroy_all
        @services.each { |id| AppointmentService.create(appointment: @appointment, service: Service.find(id)) }
      end

      def authorized_to_update?
        return false if @appointment.status != 'hold' && (update_params[:start_date] || update_params[:end_date])
        return true if @appointment.status == 'hold' && @appointment.customer == current_user
        return true if @appointment.seller == current_user || @appointment.seller.admin == current_admin

        false
      end

      def update_params
        @appointment.seller == current_user ? appointment_params_seller : appointment_params
      end

      def unauthorized_error_message
        "You can't modify this appointment, because you're not the creator or the status is not hold or you want modifying date after accepted status."
      end
    end
  end
end
