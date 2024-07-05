class AvailabilitiesController < ApplicationController
  before_action :authenticate_user!

  def index
    render json: { list: Availability.all, dates: Availability.availabilities }
  end

  def create
    puts "########{current_user.role}###########"
    if current_user.role == "admin"
      @availability = Availability.new(availability_params)
      if @availability.save
        render json: { message: "Availability created."}
      else
        render json: { message: @availability.errors.messages }
      end
    else
      render json: { message: "You need to be Admin for create availability." }
    end
  end

  def destroy
    if current_user.role == "admin"
      @availability = Availability.find(params[:id])
      if @availability.destroy
        render json: { message: "Availability destroyed."}
      else
        render json: { message: @availability.errors.messages }
      end
    else
      render json: { message: "You need to be Admin for create availability." }
    end
  end

  private

  def availability_params
    params.require(:availability).permit(:start_date, :end_date, :available)
  end
end
