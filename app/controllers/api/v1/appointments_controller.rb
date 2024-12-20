# frozen_string_literal: true

module Api
  module V1
    # Appointment controller
    class AppointmentsController < ApiController
      before_action :set_appointment, only: %i[show update]
      before_action :set_services_list, only: %i[create update]

      # @summary Returns the list of Appointment.
      # @response Appointments founded.(200) [Hash{message: String, data: Array<Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer }>}]
      # @response_example Appointments founded.(200) [{message: "Appointments founded.", data: [{id: 1, start_date: "2024-08-28T13:15:00.000+02:00", end_date: "2024-08-28T13:30:00.000+02:00", status: "hold", comment: "For my favourite son.", seller_comment: "Ok for me.", price: 36.99, seller_id: 3, customer_id: 4}] }]
      # @response Appointments not founded.(404) [Hash{message: String}]
      # @response_example Appointments not founded.(404) [{message: "Appointment(s) not founded."}]
      # @response You need to be the seller or the customer or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be the seller or the customer or Admin to perform this action.(403) [{message: "You need to be the seller or the customer or Admin to perform this action."}]
      # @tags appointments
      # @auth [bearer_jwt]
      def index
        appointments = Appointment.where(customer_id: current_user.id).or(Appointment.where(seller_id: current_user.id))
        serialized_appointments = appointments.map do |appointment|
          AppointmentSerializer.new(appointment).serializable_hash.dig(:data, :attributes)
        end
        return render_success('Appointments found.', serialized_appointments, :ok) if serialized_appointments.count.positive?
        render_error('Appointments not found.', :not_found)
      rescue ActiveRecord::RecordNotFound
      end

      # @summary Returns an Appointment.
      # @response Appointment founded.(200) [Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer }}]
      # @response_example Appointment founded.(200) [{message: "Appointment founded.", data: {id: 1, start_date: "2024-08-28T13:15:00.000+02:00", end_date: "2024-08-28T13:30:00.000+02:00", status: "hold", comment: "For my favourite son.", seller_comment: "Ok for me.", price: 36.99, seller_id: 3, customer_id: 4}}]
      # @response Appointment not founded.(404) [Hash{message: String}]
      # @response_example Appointment not founded.(404) [{message: "Appointment not founded."}]
      # @response You need to be the seller or the customer or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be the seller or the customer or Admin to perform this action.(403) [{message: "You need to be the seller or the customer or Admin to perform this action."}]
      # @tags appointments
      # @auth [bearer_jwt]
      def show
        return if authorization

        appointment = AppointmentSerializer.new(@appointment).serializable_hash.dig(:data, :attributes)
        services = @appointment.services.map do |service|
          ServiceSerializer.new(service).serializable_hash.dig(:data, :attributes)
        end
        render_success('Appointment found.', { appointment:, services: }, :ok)
      end

      # @summary Create an Appointment.
      # - end_date it's autocalculated by appointment_services list by default.
      # -Optional: End_date can be overrided.
      # @request_body The Appointment to be created [!Hash{appointment: Hash{start_date: Datetime, end_date: Datetime, comment: String}, appointment_services: Array<Integer> }]
      # @request_body_example The Appointment to be created [Hash] {appointment: {start_date: '14/07/2024 10:00',end_date: '14/07/2024 10:30', comment: 'For my son.'}, appointment_services: Array[17, 21]}
      # @response Appointment created.(201) [Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer}}]
      # @response_example Appointment created.(201) [{message: "Appointment created.", data: {id: 1, start_date: "2024-07-14T10:00:00.000+02:00", end_date: "2024-07-14T10:30:00.000+02:00", status: "hold", comment: "For my son.", seller_comment: "", price: 36.99, seller_id: 3, customer_id: 4}}]
      # @response You need to be the seller or the customer or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be the seller or the customer or Admin to perform this action.(403) [{message: "You need to be the seller or the customer or Admin to perform this action."}]
      # @response Can't create appointment.(422) [Hash{message: String, errors: Hash}]
      # @response_example Can't create appointment.(422) [{message: "Can't create appointment.", errors: {start_date: ["Can't be blank."]}}]
      # @tags appointments
      # @auth [bearer_jwt]
      def create
        return render_error('Appointment_services OR End_date required!', :unprocessable_entity) unless @services || params.dig(:appointment, :end_date)
        return render_error('Seller_id required!', :unprocessable_entity) if @services.nil? && params.dig(:appointment, :seller_id).nil?

        @appointment = Appointment.new(appointment_params)
        @appointment.seller = @services.sample.user
        return render_error('Seller not founded!', :unprocessable_entity) unless @appointment.seller || User.exists?(id: params.dig(:appointment, :seller_id))

        calculate_end_date unless params.dig(:appointment, :end_date)
        @appointment.customer = current_user
        @appointment.price = @services.sum(&:price) unless @services.nil?
        if @appointment.save
          create_appointment_services unless @services.nil?
          render_success('Appointment created.', AppointmentSerializer.new(@appointment).serializable_hash.dig(:data, :attributes), :created)
        else
          render_error("Can't create appointment:", @appointment.errors.full_messages.to_sentence, :unprocessable_entity)
        end
      end

      # @summary Update an Appointment.
      # - start_date greater than now.
      # - end_date greater than start_date.
      # - seller_comment optionnal.
      # - status is hold on creating Appointment.
      # - status can be accepted, finished, canceled.
      # - Can't modifying date after accepted status.
      # @request_body The Appointment to be updated [!Hash{appointment: Hash{start_date: DateTime, end_date: DateTime, status: String, comment: String, seller_comment: String, price: Float}}]
      # @request_body_example The Appointment to be updated [Hash] {appointment: {start_date: '14/07/2024 10:00',end_date: '14/07/2024 10:30', status: "accepted", seller_comment: "It's ok for me."}}
      # @response Appointment updated.(200) [Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer}}]
      # @response_example Appointment updated.(200) [{message: "Appointment updated.", data: {id: 1, start_date: "2024-07-14T10:00:00.000+02:00", end_date: "2024-07-14T10:30:00.000+02:00", status: "accepted", comment: "For my son.", seller_comment: "It's ok for me.", price: 36.99, seller_id: 3, customer_id: 4}}]
      # @response You need to be the seller or the customer or Admin to perform this action.(401) [Hash{message: String}]
      # @response_example You need to be the seller or the customer or Admin to perform this action.(401) [{message: "You need to be the seller or the customer or Admin to perform this action."}]
      # @response You can't modify this appointment, because you're not the creator of this appointment, the appointment status is not hold or you want modifying date after accepted status.(403) [Hash{message: String}]
      # @response_example You can't modify this appointment, because you're not the creator of this appointment, the appointment status is not hold or you want modifying date after accepted status.(403) [{message: "You can't modify this appointment, because you're not the creator of this appointment, the appointment status is not hold or you want modifying date after accepted status."}]
      # @response Can't update appointment.(422) [Hash{message: String, errors: Hash}]
      # @response_example Can't update appointment.(422) [{message: "Can't update appointment.", errors: {start_date: ["Can't be blank."]}}]
      # @tags appointments
      # @auth [bearer_jwt]
      def update
        return render_error(unauthorized_error_message, :forbidden) unless authorized_to_update?

        if @appointment.update(update_params)
          create_appointment_services unless @services.nil?
          render_success('Appointment updated.', AppointmentSerializer.new(@appointment).serializable_hash.dig(:data, :attributes), :ok)
        else
          render_error("Can't update appointment.", @appointment.errors.full_messages.to_sentence, :unprocessable_entity)
        end
      end

      private

      def calculate_end_date
        @appointment.end_date = @appointment.start_date.to_datetime + @services.sum(&:time).minutes
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
        params.require(:appointment).permit(:start_date, :end_date, :comment, :seller_id, :price)
      end

      def appointment_params_seller
        params.require(:appointment).permit(:start_date, :end_date, :status, :seller_comment, :price)
      end

      def set_appointment
        @appointment = Appointment.find_by(id: params[:id])
        render_error("Appointment #{params[:id]} could not be found.", :not_found) unless @appointment
      end

      def set_services_list
        return unless params[:appointment_services].present?

        @services = params[:appointment_services].map do |service_id|
          service = Service.by_admin(current_user.admin).find_by(id: service_id)
          return render_error('Service not found', :not_found) unless service

          service
        end
      end

      def create_appointment_services
        @appointment.appointment_services.destroy_all
        @services.each { |service| AppointmentService.create(appointment: @appointment, service:) }
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
