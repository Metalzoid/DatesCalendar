module Api
  module V1
    class AvailabilitiesController < ApiController
      before_action :authenticate_user!
      before_action :set_availability, only: %i[update destroy]
      before_action :authorize_admin!, only: %i[create update destroy]

      def index
        @availabilities = fetch_availabilities
        @dates = generate_dates(@availabilities, params[:time])

        render json: { availabilities: @availabilities, dates: @dates }, status: :ok
      end

      def index_sellers
        @sellers = User.where(role: 'seller')
        render json: { sellers: @sellers }, status: :ok
      end

      def create
        @availability = Availability.new(availability_params)
        @availability.user = current_user
        if params[:time] && @availability.available
          DateManagerService.new(@availability, params[:time], current_user).call
          render json: { message: 'Availabilities created with min and max time.' }, status: :created
        elsif @availability.save
          render json: { message: 'Availability created.', data: @availability }, status: :created
        else
          render json: { errors: @availability.errors.messages }
        end
      end

      def update
        if @availability.update(availability_params)
          render json: { message: 'Availability updated.', data: @availability }, status: :ok
        else
          render json: { errors: @availability.errors.messages }
        end
      end

      def destroy
        if @availability.destroy
          render json: { message: 'Availability destroyed.' }, status: :ok
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
        render json: { errors: "Availability #{params[:id]} could not be found." }, status: :not_found unless @availability
      end

      def authorize_admin!
        return if !current_admin.nil? || current_user.role == 'seller'

        render json: { message: 'You need to be Vendor to perform this action.' }, status: :forbidden
      end

      def fetch_availabilities
        availabilities = Availability.all
        availabilities = availabilities.where(user_id: params[:user]) if params[:user]
        availabilities
      end

      def generate_dates(availabilities, interval)
        if interval
          availabilities.where(available: true).flat_map do |availability|
            split_get_availability(availability.start_date, availability.end_date, interval.to_i)
          end
        else
          availabilities.where(available: true).map do |availability|
            { from: availability.start_date, to: availability.end_date }
          end
        end
      end

      def split_get_availability(start_date, end_date, interval)
        intervals = []
        while start_date < end_date
          interval_end = [start_date + interval.minutes, end_date].min
          intervals << { from: start_date, to: interval_end }
          start_date = interval_end
        end
        intervals
      end
    end
  end
end
