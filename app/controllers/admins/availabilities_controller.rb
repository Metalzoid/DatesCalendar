# app/controllers/admins/availabilities_controller.rb
module Admins
  class AvailabilitiesController < AdminsPagesController
    before_action :authorize_data_admin, only: %i[index destroy]
    before_action :set_users, only: %i[index]

    def index
      filter_users_with_availabilities
      @availabilities = @users.flat_map(&:availabilities)
      @availability = Availability.new
      filter_availabilities_by_user_id if params[:user_id].present? && params[:user_id] != 'none'
      respond_to_formats('availabilities_infos', availabilities: @availabilities.sort_by(&:start_date))
    end

    def create
      @availability = Availability.new(availability_params)
      params[:time].delete_if { |_key, value| value.blank? }
      if params[:time].present? && @availability.valid?
        handle_time_params
      elsif @availability.valid?
        ActiveRecord::Base.transaction do
          @availability.save!
          redirect_to admins_availabilities_url(user_id: @availability.user_id)
        end
      else
        respond_to_errors_create(@availability)
      end
    end

    def destroy
      @availability = Availability.find(params[:id])
      if params[:listed].present? && @availability.user.availabilities.length > 1
        redirect_to "#{admins_availabilities_url}?user_id=#{params[:user_id]}" if @availability.destroy
      elsif @availability.destroy
        redirect_to admins_availabilities_path
      end
    end

    private

    def availability_params
      params.require(:availability).permit(:start_date, :end_date, :available, :user_id)
    end

    def set_users
      @users = current_admin.users
    end

    def filter_users_with_availabilities
      @users = @users.select { |user| user.availabilities.any? }
    end

    def filter_availabilities_by_user_id
      @availabilities = Availability.where(user_id: params[:user_id]).sort_by(&:start_date)
    end

    def respond_to_formats(partial_name, locals)
      respond_to do |format|
        format.html
        format.text { render(partial: "admins/availabilities/#{partial_name}", locals:, formats: [:html]) }
      end
    end

    def handle_time_params
      @availabilities = DateManagerService.new(@availability, params[:time], @availability.user).call
      @availabilities.map(&:save!)
      @availabilities_serialized = @availabilities.map do |availability|
        AvailabilitySerializer.new(availability).serializable_hash.dig(:data, :attributes)
      end
    end
  end
end
