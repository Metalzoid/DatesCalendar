# frozen_string_literal: true
#
require 'pry-byebug'
module Api
  module V1
    # Availabilities controller
    class AvailabilitiesController < ApiController
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
      # @response Availabilities founded.(200) [Hash{message: String, data: Hash{availabilities: Array<Hash{id: Integer, start_date: Datetime, end_date: Datetime, available: Boolean, user_id: Integer}>, dates: Array<Hash{from: Datetime, to: Datetime}>}}]
      # @response_example Availabilities founded.(200) [{message: "Availabilitie(s) founded.", data: {availabilities: [{id: 1, start_date: "2024-07-14T09:00:00.000+02:00", end_date: "2024-07-14T18:30:00.000+02:00", available: true, user_id: 3}], dates:[{from: "2024-07-14T09:00:00.000+02:00", to: "2024-08-14T18:30:00.000+02:00"}] }}]
      # @response Availabilities not founded.(404) [Hash{message: String}]
      # @response_example Availabilities not founded.(404) [{message: "Availabilities not founded."}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be Seller or Admin to perform this action.(403) [{message: "You need to be Seller or Admin to perform this action."}]
      # @response Seller_id required.(400) [Hash{message: String}]
      # @response_example Seller_id required.(400) [{message: "Seller_id required."}]
      # @tags availabilities
      # @auth [bearer_jwt]
      def index
        @seller = current_user if %w[seller both].include?(current_user.role)
        @seller = User.find(params[:seller_id]) if params[:seller_id].present?
        @available = params[:available] || true
        return render_error('Seller id required.', :bad_request) unless @seller
        return render_error('Seller not found.', :not_found) unless @seller

        @availabilities = fetch_availabilities(@seller)
        @availabilities_serialized = @availabilities.map do |availability|
          AvailabilitySerializer.new(availability).serializable_hash[:data][:attributes]
        end
        return render_error('Availabilities or Unavailabilities not founded.', :not_found) if @availabilities.empty?

        params_dates = {}
        params_dates[:availabilities] = @availabilities
        params_dates[:interval] = params[:interval] if params[:interval]
        @dates = generate_dates(params_dates) if @availabilities
        render_success('Availabilities founded.', { availabilities: @availabilities_serialized, dates: @dates }, :ok)
      end

      # @summary Create an Availability.
      # - Optionnal: Min and Max time for split Availabilities.
      # @request_body The availability to be created [!Hash{availability: Hash{start_date: Datetime, end_date: Datetime, available: Boolean}, time: Hash{ min_hour: Integer, min_minutes: Integer, max_hour: Integer, max_minutes: Integer }}]
      # @request_body_example A complete availability. [Hash] {availability: {start_date: '14/07/2024 10:00', end_date: '15/07/2024 17:00', available: 'true'}, time: {min_hour: 7, min_minutes: 30, max_hour: 19, max_minutes: 0}}
      # @response Availability created.(201) [Hash{message: String, data: Array<Hash{id: Integer, start_date: Datetime, end_date: Datetime, available: Boolean, user_id: Integer}>}]
      # @response_example Availability created.(201) [{message: "Availability created.", data: [{id: 11, start_date: "2024-07-14T10:00:00.000+02:00", end_date: "2024-07-14T19:00:00.000+02:00", available: true, user_id: 3}, {id: 12, start_date: "2024-07-15T07:30:00.000+02:00", end_date: "2024-07-15T17:00:00.000+02:00", available: true, user_id: 3} ]}]
      # @response You need to be a Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be a Seller or Admin to perform this action.(403) [{message: "You need to be a Seller or Admin to perform this action."}]
      # @response Can't create availability.(422) [Hash{message: String, errors: Hash}]
      # @response_example Can't create availability.(422) [{message: "Can't create availability.", errors: {start_date: ["Can't be blank"]}}]
      # @tags availabilities
      # @auth [bearer_jwt]
      def create
        return render_error('You need to be a Seller or Admin to perform this action.', :unauthorized) unless current_admin || %w[seller both].include?(current_user.role)

        @availability = Availability.new(availability_params)
        @availability.user = current_user
        if params[:time] && @availability.valid?
          handle_time_params
        elsif @availability.save
          render_success('Availability created.', AvailabilitySerializer.new(@availability).serializable_hash[:data][:attributes], :created)
        else
          render_error("Can't create availability.", @availability.errors.messages, :unprocessable_entity)
        end
      end

      # @summary Update an Availability.
      # @request_body The availability to be updated [Hash{availability: Hash{start_date: Datetime, end_date: Datetime, available: Boolean}}]
      # @request_body_example A complete availability. [Hash] {availability: {start_date: '14/07/2024 10:00', end_date: '14/07/2024 17:00', available: 'true'}}
      # @response Availability updated.(200) [Hash{message: String, availability: Hash{id: Integer, start_date: Datetime, end_date: Datetime, available: Boolean, user_id: Integer}}]
      # @response_example Availability updated.(200) [{message: "Availability updated.", availability: {id: 17, start_date: "2024-07-14T10:00:00.000+02:00", end_date_date: "2024-07-14T17:00:00.000+02:00", available: true, user_id: 3}}]
      # @response Availability {id} could not be found.(404) [Hash{message: String}]
      # @response_example Availability {id} could not be found.(404) [{message: "Availability 9885 could not be found."}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be Seller or Admin to perform this action.(403) [{message: "You need to be Seller or Admin to perform this action."}]
      # @response Can't update availability.(422) [Hash{message: String, errors: Hash}]
      # @response_example Can't update availability.(422) [{message: "Can't update availability.", errors: {start_date: ["Can't be blank"]}}]
      # @tags availabilities
      # @auth [bearer_jwt]
      def update
        if @availability.update(availability_params)
          return render_success('Availability updated.', AvailabilitySerializer.new(@availability).serializable_hash[:data][:attributes], :ok)
        end

        render_error("Can't update availability.", @availability.errors.messages, :unprocessable_entity)
      end

      # @summary Destroy an Availability.
      # @response Availability destroyed.(200) [Hash{message: String, data: Hash{id: Integer, start_date: Datetime, end_date: Datetime, available: Boolean, user_id: Integer}}]
      # @response_example Availability destroyed.(200) [{message: "Availability destroyed.", data: {id: 3, start_date: "2024-07-14T10:00:00.000+02:00", end_date: "2024-07-14T17:00:00.000+02:00", available: true, user_id: 3}}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be Seller or Admin to perform this action.(403) [{message: "You need to be Seller or Admin to perform this action."}]
      # @response Availability {id} could not be found.(404) [Hash{message: String}]
      # @response_example Availability {id} could not be found.(404) [{message: "Availability 9855 could not be found."}]
      # @response Can't destroy availability.(422) [Hash{message: String, errors: Hash}]
      # @response_example Can't destroy availability.(422) [{message: "Can't destroy availability.", errors: {start_date: ["Can't be blank"]}}]
      # @tags availabilities
      # @auth [bearer_jwt]
      def destroy
        return render_success('Availability destroyed.', AvailabilitySerializer.new(@availability).serializable_hash[:data][:attributes], :ok) if @availability.destroy

        render_error("Can't destroy availability.", @availability.errors.messages, :unprocessable_entity)
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

      def fetch_availabilities(seller)
        Availability.by_admin(seller.admin).where(available: @available, user: seller)
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
          @availabilities_serialized = @availabilities.map do |availability|
            AvailabilitySerializer.new(availability).serializable_hash[:data][:attributes]
          end
          render_success('Availabilities created with min and max time.', @availabilities_serialized, :created)
        else
          render_error('Start time is not included in the params time', :unprocessable_entity)
        end
      end
    end
  end
end
