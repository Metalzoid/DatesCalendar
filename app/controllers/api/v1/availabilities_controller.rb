module Api
  module V1
    class AvailabilitiesController < ApiController
      before_action :authenticate_user!
      before_action :set_availability, only: %i[update destroy]
      before_action :authorize_admin!, only: %i[create update destroy]

      def index
        @availabilities = fetch_availabilities(params[:seller_id])
        return render_error('Seller id required') if params[:seller_id].nil?
        return render_error('Seller not found') unless User.find_by(id: params[:seller_id])
        return render_error('Availabilities not found') if @availabilities.count.zero?

        @dates = generate_dates(@availabilities, params[:interval]) if @availabilities && params[:interval]
        render_success('Availabilities founded.', { availabilities: @availabilities, dates: @dates }, :ok)
      end

      def create
        @availability = Availability.new(availability_params)
        @availability.user = current_user

        if params[:time] && @availability.valid?
          handle_time_params
        elsif @availability.save
          render_success('Availability created.', @availability, :created)
        else
          render_error(@availability.errors.messages)
        end
      end

      def update
        if @availability.update(availability_params)
          render_success('Availability updated.', @availability, :ok)
        else
          render_error(@availability.errors.messages)
        end
      end

      def destroy
        if @availability.destroy
          # render json: { message: 'Availability destroyed.' }, status: :ok
          render_success('Availability destroyed.', @availability, :ok)
        else
          render_error(@availability.errors.messages)
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
        return if current_admin || current_user.role == 'seller'

        render json: { message: 'You need to be Vendor to perform this action.' }, status: :unauthorized
      end

      def fetch_availabilities(seller_id)
        availabilities = Availability.where(available: check_route_path, user_id: seller_id)
        availabilities = availabilities.where(user_id: params[:user]) if params[:user]
        availabilities
      end

      def generate_dates(availabilities, interval)
        if interval
          availabilities.where(available: check_route_path).flat_map do |availability|
            split_get_availability(availability.start_date, availability.end_date, interval.to_i)
          end
        else
          availabilities.where(available: check_route_path).map do |availability|
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

      def check_route_path
        request.fullpath.include?('unavailabilities') ? false : true
      end

      def handle_time_params
        min_hour = params[:time][:min_hour]
        max_hour = params[:time][:max_hour]

        if (min_hour..max_hour).include?(@availability.start_date.hour)
          @availabilities = DateManagerService.new(@availability, params[:time], current_user).call
          render_success('Availabilities created with min and max time.', @availabilities, :created)
        else
          render_error('Start time is not included in the params time')
        end
      end
    end
  end
end
