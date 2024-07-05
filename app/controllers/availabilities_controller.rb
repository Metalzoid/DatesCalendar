class AvailabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_availability, only: %i[update destroy]

  def index
    render json: { list: Availability.all, dates: Availability.availabilities }
  end

  def create
    if current_user.role == "admin"
      @availability = Availability.new(availability_params)
      if @availability.save
        render json: { message: "Availability created."}
      else
        render json: { errors: @availability.errors.messages }
      end
    else
      render json: { message: "You need to be Admin for create availability." }
    end
  end

  def update
    if current_user.role == "admin"
      if @availability.update(availability_params)
        render json: { message: "Availability updated."}
      else
        render json: { errors: @availability.errors.messages }
      end
    else
      render json: { message: "You need to be Admin for update availability." }
    end
  end

  def destroy
    if current_user.role == "admin"
      if @availability.destroy
        render json: { message: "Availability destroyed."}
      else
        render json: { errors: @availability.errors.messages }
      end
    else
      render json: { errors: "You need to be Admin for create availability." }
    end
  end

  private

  def availability_params
    params.require(:availability).permit(:start_date, :end_date, :available)
  end

  def set_availability
    if Availability.where(id: params[:id]).exists?
      @availability = Availability.find(params[:id])
    else
      render json: { errors: "Availability not found. Verify ID."}
    end
  end
end
