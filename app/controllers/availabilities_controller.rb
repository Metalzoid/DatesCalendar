class AvailabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_availability, only: %i[update destroy]
  before_action :authorize_admin!, only: %i[create update destroy]

  def index
    render json: { list: Availability.all, dates: Availability.availabilities }
  end

  def create
    @availability = Availability.new(availability_params)
    if @availability.save
      render json: { message: "Availability created."}
      if current_user.role == "vendor" && @availability.available == false
        @availability.mailer({start_date: @availability.start_date, end_date: @availability.end_date, template_uuid: 'eff70055-6107-4bee-9c08-ad829db8dcd4'})
      elsif current_user.role == "vendor" && @availability.available == true
        @availability.mailer({start_date: @availability.start_date, end_date: @availability.end_date, template_uuid: 'd2f2779b-3b07-4770-85a1-f86a06d8e62b'})
      end
    else
      render json: { errors: @availability.errors.messages }
    end
  end

  def update
    if @availability.update(availability_params)
      render json: { message: "Availability updated."}
    else
      render json: { errors: @availability.errors.messages }
    end
  end

  def destroy
    if @availability.destroy
      render json: { message: "Availability destroyed."}
    else
      render json: { errors: @availability.errors.messages }
    end
  end

  private

  def availability_params
    params.require(:availability).permit(:start_date, :end_date, :available)
  end

  def set_availability
    @availability = Availability.find_by(id: params[:id])
    unless @availability
      render json: { errors: "Availability #{params[:id]} could not be found." }, status: :not_found
    end
  end

  def authorize_admin!
    unless current_user.role == "vendor"
      render json: { message: "You need to be Vendor to perform this action." }, status: :forbidden
    end
  end
end
