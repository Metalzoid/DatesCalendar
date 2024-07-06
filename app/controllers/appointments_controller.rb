class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: %i[show update]

  def index
    @appointments = Appointment.all
    if current_user.role == "user"
      @appointments = @appointments.where(user: current_user)
    end
    render json: @appointments
  end

  def show
    render json: @appointment
  end

  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.user = current_user
    if @appointment.save
      render json: { message: "Appointment created." }
    else
      render json: { errors: @appointment.errors.messages }
    end
  end

  def update
    if @appointment.status == "hold" && @appointment.user == current_user
      if @appointment.update(appointment_params)
        render json: { message: "Appointment updated." }
      else
        render json: { errors: @appointment.errors.messages }
      end
    elsif current_user.role == "admin"
      if @appointment.update(appointment_params_admin)
        render json: { message: "Appointment updated." }
      else
        render json: { errors: @appointment.errors.messages }
      end
    else
      render json: { errors: "You can't modify this appointment, because you're not the creator of this appointment, or the appointment status is not hold." }
    end
  end


  private

  def appointment_params
    params.require(:appointment).permit(:start_date, :end_date, :comment, :status)
  end

  def appointment_params_admin
    params.require(:appointment).permit(:status, :admin_comment)
  end

  def set_appointment
    if Appointment.where(id: params[:id]).exists?
      @appointment = Appointment.find(params[:id])
    else
      render json: { errors: "Appointment not found. Verify ID."}
    end
  end

end
