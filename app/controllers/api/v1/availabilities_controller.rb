# frozen_string_literal: true

module Api
  module V1
    # Availabilities controller
    class AvailabilitiesController < ApiController
      before_action :authenticate_user!
      before_action :set_availability, only: %i[update destroy]
      before_action :authorize_seller!, only: %i[update destroy]

      # @summary Returns the list of Availabilities.
      # - Required: Seller ID.
      # - Optionnal: Available status (true || false). Default: true
      # - Optionnal: Format Availabilities by interval of minutes.
      # - URL exemple: /api/v1/availabilities?seller_id=1&interval=30&available=false
      # @parameter seller_id(query) [Integer] The seller ID.
      # @parameter available(query) [Boolean] The available status.
      # @parameter interval(query) [Integer] The interval expressed in minutes for split dates.
      # @response Availabilities founded.(200) [Hash] {message: String, data: Hash, data[availabilities]: Hash, data[dates]: Hash}
      # @response Availabilities not founded.(404) [Hash] {message: String}
      # @response You need to be Seller or Admin to perform this action.(403) [Hash] {message: String}
      # @response Seller_id required.(400) [Hash] {message: String}
      # @response Seller not found.(404) [Hash] {message: String}
      # @tags availabilities
      # @auth [bearer_jwt]
      def index
        params[:available] ? @available = params[:available] : @available = true
        return render_error('Seller id required.', :bad_request) if params[:seller_id].nil?
        return render_error('Seller not found.', :not_found) unless User.find_by(id: params[:seller_id])
        @availabilities = fetch_availabilities(params[:seller_id])
        return render_error("Availabilities or Unavailabilities not founded.", :not_found) if @availabilities.empty?

        params_dates = {}
        params_dates[:availabilities] = @availabilities
        params_dates[:interval] = params[:interval] if params[:interval]
        @dates = generate_dates(params_dates) if @availabilities
        render_success('Availabilities founded.', { availabilities: @availabilities, dates: @dates }, :ok)
      end

      # @summary Create an Availability.
      # - Optionnal: Min and Max time for split Availabilities.
      # @request_body The availability to be created [Hash] {availability: {start_date: String, end_date: String, available: String}, time: { min_hour: Integer, min_minutes: Integer, max_hour: Integer, max_minutes: Integer }}
      # @request_body_example A complete availability. [Hash] {availability: {start_date: '14/07/2024 10:00', end_date: '14/07/2024 17:00', available: 'true'}, time: {min_hour: 7, min_minutes: 30, max_hour: 19, max_minutes: 0}}
      # @response You need to be Seller or Admin to perform this action.(403) [Hash] {message: String}
      # @response Availability created.(201) [Hash] {message: String, data: Hash}
      # @response Can't create availability.(422) [Hash] {message: String}
      # @tags availabilities
      # @auth [bearer_jwt]
      def create
        return render_error('You need to be the Seller or Admin to perform this action.', :unauthorized) unless current_admin || ['seller', 'both'].include?(current_user.role)

        @availability = Availability.new(availability_params)
        @availability.user = current_user
        if params[:time] && @availability.valid?
          handle_time_params
        elsif @availability.save
          render_success('Availability created.', @availability, :created)
        else
          render_error("Can't create availability. #{@availability.errors.messages}", :unprocessable_entity)
        end
      end

      # @summary Update an Availability.
      # @request_body The availability to be updated [Hash] {availability: {start_date: String, end_date: String, available: String}}
      # @request_body_example A complete availability. [Hash] {availability: {start_date: '14/07/2024 10:00', end_date: '14/07/2024 17:00', available: 'true'}}
      # @response You need to be Seller or Admin to perform this action.(403) [Hash] {message: String}
      # @response Availability {{id}} could not be found.(404) [Hash] {message: String}
      # @tags availabilities
      # @auth [bearer_jwt]
      def update
        return render_success('Availability updated.', @availability, :ok) if @availability.update(availability_params)

        render_error("Can't update availability. #{@availability.errors.messages}", :unprocessable_entity)
      end

      # @summary Destroy an Availability.
      # @response You need to be Seller or Admin to perform this action.(403) [Hash] {message: String}
      # @response Availability {{id}} could not be found.(404) [Hash] {message: String}
      # @response Availability destroyed.(200) [Hash] {message: String, data: Hash}
      # @response Can't destroy availability.(422) [Hash] {message: String}
      # @tags availabilities
      # @auth [bearer_jwt]
      def destroy
        return render_success('Availability destroyed.', @availability, :ok) if @availability.destroy

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
        return if current_admin || @availability.user == current_user

        render_error('You need to be the Seller or Admin to perform this action.', :unauthorized)
      end

      def fetch_availabilities(seller_id)
        Availability.by_admin(User.find(seller_id).admin).where(available: @available, user_id: seller_id)
      end

      def generate_dates(params = {})
        if params[:interval]
          params[:availabilities].where(available: @available).flat_map do |availability|
            split_get_availability(availability.start_date, availability.end_date, params[:interval].to_i)
          end
        else
          params[:availabilities].where(available: @available).map do |availability|
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
