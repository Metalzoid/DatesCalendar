class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: %i[show]

  def index
    @appointments = Appointment.all
    if current_user.role == "user"
      @appointments = @appointments.where(user: current_user)
    end
    render json: @appointments.to_json
  end

  def show
    render json: @appointment.to_json
  end


  private

  def appointment_params
    params.require(:appointment).permit(:start_date, :end_date, :comment)
  end

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end
end
