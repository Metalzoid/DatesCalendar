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
        @appointments = Appointment.where(customer_id: current_user.id).or(Appointment.where(seller_id: current_user.id))
        @appointments_serialized = @appointments.map do |appointment|
          AppointmentSerializer.new(appointment).serializable_hash[:data][:attributes]
        end
        return render_success('Appointment(s) founded.', @appointments_serialized, :ok) unless @appointments.empty?

        render_error('Appointment(s) not founded.', :not_found)
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

        render_success('Appointment founded.', AppointmentSerializer.new(@appointment).serializable_hash[:data][:attributes], :ok)
      end

      # @summary Create an Appointment.
      # - end_date it's autocalculated by appointment_services list by default.
      # -Optional: End_date can be overrided.
      # @request_body The Appointment to be created [!Hash{appointment: Hash{start_date: Datetime, end_date: Datetime, comment: String}, appointment_services: Array<Integer> }]
      # @request_body_example The Appointment to be created [Hash] {appointment: {start_date: '14/07/2024 10:00',end_date: '14/07/2024 10:30', comment: 'For my son.'}, appointment_services: "En attente"}
      # @response Appointment created.(201) [Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer}}]
      # @response_example Appointment created.(201) [{message: "Appointment created.", data: {id: 1, start_date: "2024-07-14T10:00:00.000+02:00", end_date: "2024-07-14T10:30:00.000+02:00", status: "hold", comment: "For my son.", seller_comment: "", price: 36.99, seller_id: 3, customer_id: 4}}]
      # @response You need to be the seller or the customer or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be the seller or the customer or Admin to perform this action.(403) [{message: "You need to be the seller or the customer or Admin to perform this action."}]
      # @response Can't create appointment.(422) [Hash{message: String}]
      # @response_example Can't create appointment.(422) [{message: "Can't create appointment."}]
      # @tags appointments
      # @auth [bearer_jwt]
      def create
        return render_error("Appointment_services OR End_date required !", :unprocessable_entity) unless @services || params[:appointment][:end_date]
        return render_error("seller_id required !", :unprocessable_entity) if @services.nil? && params[:appointment][:seller_id].nil?

        @appointment = Appointment.new(appointment_params)
        calculate_end_date unless params[:appointment][:end_date]
        @appointment.customer = current_user
        @appointment.seller = Service.find(@services.first).user if @services
        if @appointment.save
          create_appointment_services(services: @services) if @services
          @appointment.update_price
          render_success('Appointment created.', AppointmentSerializer.new(@appointment).serializable_hash[:data][:attributes], :created)
        else
          render_error("Can't create appointment #{@appointment.errors.messages}", :unprocessable_entity)
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
      # @request_body_example The Appointment to be updated [Hash] {appointment: {start_date: '14/07/2024 10:00',end_date: '14/07/2024 10:30', status: "accepted", seller_comment: "It's ok for me."}, appointment_services: "En attente"}
       # @response Appointment updated.(200) [Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, status: String, comment: String, seller_comment: String, price: Float, seller_id: Integer, customer_id: Integer}}]
      # @response_example Appointment updated.(200) [{message: "Appointment updated.", data: {id: 1, start_date: "2024-07-14T10:00:00.000+02:00", end_date: "2024-07-14T10:30:00.000+02:00", status: "accepted", comment: "For my son.", seller_comment: "It's ok for me.", price: 36.99, seller_id: 3, customer_id: 4}}]
      # @response You need to be the seller or the customer or Admin to perform this action.(401) [Hash{message: String}]
      # @response_example You need to be the seller or the customer or Admin to perform this action.(401) [{message: "You need to be the seller or the customer or Admin to perform this action."}]
      # @response You can't modify this appointment, because you're not the creator of this appointment, the appointment status is not hold or you want modifying date after accepted status.(403) [Hash{message: String}]
      # @response_example You can't modify this appointment, because you're not the creator of this appointment, the appointment status is not hold or you want modifying date after accepted status.(403) [{message: "You can't modify this appointment, because you're not the creator of this appointment, the appointment status is not hold or you want modifying date after accepted status."}]
      # @tags appointments
      # @auth [bearer_jwt]
      def update
        if authorized_to_update?
          return handle_successful_update if @appointment.update(update_params)

          render_error("Error. #{@appointment.errors.messages}", :unprocessable_entity)
        else
          render_error(unauthorized_error_message, :unprocessable_entity)
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
        params.require(:appointment).permit(:start_date, :end_date, :status, :seller_comment)
      end

      def set_appointment
        @appointment = Appointment.find_by(id: params[:id])
        return if @appointment

        render_error("Appointment #{params[:id]} could not be found.", :not_found)
      end

      def set_services_list
        @services = params[:appointment_services]
      end

      def create_appointment_services(params = {})
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
        render_success('Appointment updated.', AppointmentSerializer.new(@appointment).serializable_hash[:data][:attributes], :ok)
      end

      def unauthorized_error_message
        "You can't modify this appointment, because you're not the creator of this appointment, the appointment status is not hold or you want modifying date after accepted status."
      end
    end
  end
end
