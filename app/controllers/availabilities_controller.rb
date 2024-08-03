class AvailabilitiesController < ApiController
  before_action :authenticate_user!
  before_action :set_availability, only: %i[update destroy]
  before_action :authorize_admin!, only: %i[create update destroy]

  ## Get Availabilities of one vendor
  # URL = url/availabilities?user={USER_ID}
  def index
    @availabilities = Availability.all
    @availabilities = @availabilities.where(user_id: params[:user]) if params[:user]
    @dates = @availabilities.where(available: true).map do |availability|
      { from: availability.start_date, to: availability.end_date }
    end
    render json: { availabilities: @availabilities, dates: @dates }
  end

  def index_sellers
    @sellers = User.where(role: 'seller')
    render json: { sellers: @sellers }
  end

  def create
    @availability = Availability.new(availability_params)
    @availability.user = current_user
    if @availability.save
      render json: { message: 'Availability created.' }
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
    return if !current_admin.nil? || current_user.role == 'seller'

    render json: { message: "You need to be Vendor to perform this action." }, status: :forbidden
  end
end
