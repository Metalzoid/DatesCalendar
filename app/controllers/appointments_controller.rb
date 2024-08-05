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
      render json: { message: 'Appointment created.' }
    else
      render json: { errors: @appointment.errors.messages }
    end
  end

  def update
    @old_start_date = @appointment.start_date
    @old_end_date = @appointment.end_date
    if @appointment.status == 'hold' && @appointment.customer == current_user
      if @appointment.update(appointment_params)
        create_appointment_service_and_price(services: @services) unless @services.nil?
        if ENV.fetch('USE_MAILTRAP') == 'true'
          @appointment.mailer_seller({ update: { old_start_date: @old_start_date,
                                                 old_end_date: @old_end_date },
                                       template_uuid: 'abaea168-a2fd-4d7c-8530-5637149234a1',
                                       from_controller: true })
        end
        render json: { message: 'Appointment updated.' }
      else
        render json: { errors: @appointment.errors.messages }
      end
    elsif current_user.role == 'seller'
      if @appointment.update(appointment_params_seller)
        render json: { message: 'Appointment updated.' }
        create_appointment_service_and_price(services: @services) unless @services.nil?
      else
        render json: { errors: @appointment.errors.messages }
      end
    else
      render json: { errors: "You can't modify this appointment, because you're not the creator of this appointment, or the appointment status is not hold." }
    end
  end

  private

  def appointment_params
    params.require(:appointment).permit(:start_date, :end_date, :comment, :status, :seller_id)
  end

  def appointment_params_seller
    params.require(:appointment).permit(:status, :seller_comment)
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
end
