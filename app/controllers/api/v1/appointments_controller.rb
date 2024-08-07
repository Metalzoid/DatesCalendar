module Api
  module V1
    class AppointmentsController < ApiController
      before_action :authenticate_user!
      before_action :set_appointment, only: %i[show update]
      before_action :set_services_list, only: %i[create update]

      def index
        @appointments = Appointment.where(customer_id: current_user.id).or(Appointment.where(seller_id: current_user.id))
        render json: @appointments
      end

      def show
        render json: @appointment
      end

      def create
        @appointment = Appointment.new(appointment_params)
        @appointment.customer = current_user
        @appointment.seller = Service.find(@services.first).user
        if @appointment.save
          create_appointment_service_and_price(services: @services)
          render json: { message: 'Appointment created.' }, status: :created
        else
          render json: { errors: @appointment.errors.messages }, status: :unprocessable_entity
        end
      end

      def update
        @old_start_date = @appointment.start_date
        @old_end_date = @appointment.end_date
        if authorized_to_update?
          if @appointment.update(update_params)
            handle_successful_update
          else
            render json: { errors: @appointment.errors.messages }, status: :ok
          end
        else
          render json: { errors: unauthorized_error_message }, status: :unprocessable_entity
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
        render json: { errors: "Appointment #{params[:id]} could not be found." }, status: :not_found unless @appointment
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
        @appointment.status == 'hold' && @appointment.customer == current_user || current_user.role == 'seller'
      end

      def update_params
        current_user.role == 'seller' ? appointment_params_seller : appointment_params
      end

      def handle_successful_update
        create_appointment_service_and_price(services: @services) unless @services.nil?
        send_update_notification if mailtrap_enabled? && current_user.role != 'seller'
        render json: { message: 'Appointment updated.' }
      end

      def mailtrap_enabled?
        ENV.fetch('USE_MAILTRAP') == 'true'
      end

      def send_update_notification
        @appointment.mailer_seller({ update: { old_start_date: @old_start_date, old_end_date: @old_end_date },
                                     template_uuid: 'abaea168-a2fd-4d7c-8530-5637149234a1',
                                     from_controller: true
        })
      end

      def unauthorized_error_message
        "You can't modify this appointment, because you're not the creator of this appointment, or the appointment status is not hold."
      end
    end
  end
end
