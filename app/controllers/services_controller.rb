class ServicesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!, only: %i[create update destroy]
  before_action :set_service, only: %i[update destroy]

  def index
    render json: Service.all
  end

  def create
    @service = Service.new(service_params)
    @service.user = current_user
    if @service.save
      render json: { message: "Service created." }
    else
      render json: { errors: @service.errors.messages }
    end
  end

  def update
    if @service.update(service_params)
      render json: { message: "Service updated." }
    else
      render json: { errors: @service.errors.message }
    end
  end

  def destroy
    if @service.destroy
      render json: { message: "Service #{@service.id} has been deleted"}
    else
      render json: { errors: @service.errors.messages }
    end
  end

  private

  def service_params
    params.require(:service).permit(:title, :price, :time)
  end

  def set_service
    @service = Service.find_by(id: params[:id])
    unless @service
      render json: { message: "Service #{params[:id]} could not be found." }, status: :not_found
    end
  end

  def authorize_admin!
    unless current_user.role == "vendor"
      render json: { message: "You need to be Vendor to perform this action." }, status: :forbidden
    end
  end

end
