class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: %i[show update]
  before_action :set_services_list, only: %i[create update]

  def index
    @appointments = Appointment.all
    if current_user.role == "enterprise"
      @appointments = @appointments.where(user: current_user)
    end
    render json: @appointments
  end

  def show
    render json: @appointment
  end

  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.client = current_user
    if @appointment.save
      create_appointment_service_and_price(services: @services)
      render json: { message: "Appointment created." }
    else
      render json: { errors: @appointment.errors.messages }
    end

  end

  def update
    @old_start_date = @appointment.start_date
    @old_end_date = @appointment.end_date
    if @appointment.status == "hold" && @appointment.client == current_user
      if @appointment.update(appointment_params)
        render json: { message: "Appointment updated." }
        create_appointment_service_and_price(services: @services) unless @services.nil?
        @appointment.mailer_update(old_start_date: @old_start_date, old_end_date: @old_end_date, new_start_date: @appointment.start_date, new_end_date: @appointment.end_date, template_uuid: "433f7b20-99e4-42e2-a502-21a37867cdf6", firstname: @appointment.client.firstname, lastname: @appointment.client.lastname, user_firstname: @appointment.client.firstname, user_lastname: @appointment.client.lastname)
        @appointment.mailer_update(old_start_date: @old_start_date, old_end_date: @old_end_date, new_start_date: @appointment.start_date, new_end_date: @appointment.end_date, template_uuid: "abaea168-a2fd-4d7c-8530-5637149234a1", firstname: "Valou", lastname: "Capdeboscq", user_firstname: @appointment.client.firstname, user_lastname: @appointment.client.lastname)
      else
        render json: { errors: @appointment.errors.messages }
      end
    elsif current_user.role == "vendor"
      if @appointment.update(appointment_params_admin)
        render json: { message: "Appointment updated." }
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
    params.require(:appointment).permit(:start_date, :end_date, :comment, :status, :vendor_id)
  end

  def appointment_params_admin
    params.require(:appointment).permit(:status, :vendor_comment)
  end

  def set_appointment
    @appointment = Appointment.find_by(id: params[:id])
    unless @appointment
      render json: { errors: "Appointment #{params[:id]} could not be found." }, status: :not_found
    end
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
