# frozen_string_literal: true

module Api
  module V1
    # Availabilities controller
    class AvailabilitiesController < ApiController
      before_action :authenticate_user!
      before_action :set_availability, only: %i[update destroy]
      before_action :authorize_seller!, only: %i[create update destroy]

      def index
        @availabilities = fetch_availabilities(params[:seller_id])
        return render_error('Seller id required', :bad_request) if params[:seller_id].nil?
        return render_error('Seller not found', :not_found) unless User.find_by(id: params[:seller_id])
        return render_error('Availabilities not found', :not_found) if @availabilities.empty?

        params_dates[:availabilities] = @availabilities
        params_dates[:interval] = params[:interval] if params[:interval]
        @dates = generate_dates(params_dates) if @availabilities
        render_success('Availabilities founded.', { data: { availabilities: @availabilities, dates: @dates } }, :ok)
      end

      def create
        @availability = Availability.new(availability_params)
        @availability.user = current_user
        if params[:time] && @availability.valid?
          handle_time_params
        elsif @availability.save
          render_success('Availability created.', { data: @availability }, :created)
        else
          render_error("Can't create availability. #{@availability.errors.messages}", :unprocessable_entity)
        end
      end

      def update
        return render_success('Availability updated.', { data: @availability }, :ok) if @availability.update(availability_params)

        render_error("Can't update availability. #{@availability.errors.messages}", :unprocessable_entity)
      end

      def destroy
        return render_success('Availability destroyed.', { data: @availability }, :ok) if @availability.destroy

        render_error("Can't destroy availability. #{@availability.errors.messages}", :unprocessable_entity)
      end

      private

      def availability_params
        params.require(:availability).permit(:start_date, :end_date, :available)
      end

      def set_availability
        @availability = Availability.find_by(id: params[:id])
        return if @availability

        render_error("Availability #{params[:id]} could not be found.", :not_found)
      end

      def authorize_seller!
        return if current_admin || current_user.role == 'seller'

        render_error('You need to be a Seller or Admin to perform this action.', :unauthorized)
      end

      def fetch_availabilities(seller_id)
        availabilities = Availability.where(available: check_route_path, user_id: seller_id)
        availabilities = availabilities.where(user_id: params[:user]) if params[:user]
        availabilities
      end

      def generate_dates(params = {})
        if params[:interval]
          params[:availabilities].where(available: check_route_path).flat_map do |availability|
            split_get_availability(availability.start_date, availability.end_date, params[:interval].to_i)
          end
        else
          params[:availabilities].where(available: check_route_path).map do |availability|
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
          render_success('Availabilities created with min and max time.', { data: @availabilities }, :created)
        else
          render_error('Start time is not included in the params time', :unprocessable_entity)
        end
      end
    end
  end
end
