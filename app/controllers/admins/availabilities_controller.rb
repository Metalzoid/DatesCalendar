# app/controllers/admins/availabilities_controller.rb
module Admins
  class AvailabilitiesController < AdminsPagesController
    before_action :authorize_data_admin, only: %i[index destroy]
    before_action :set_users, only: %i[index]

    def index
      filter_users_with_availabilities
      @availabilities = @users.flat_map(&:availabilities)
      @availability = Availability.new
      return unless params[:user_id].present? && @availabilities.any?

      filter_availabilities_by_user_id
      respond_to_formats('availabilities_infos', availabilities: @availabilities)
    end

    def create
      @availability = Availability.new(availability_params)
      if @availability.save
        respond_to do |format|
          format.html { redirect_to admins_availabilities_path }
          format.json { render json: { success: true, partial: render_to_string(partial: 'admins/availabilities/availability', locals: { availability: @availability }, formats: [:html]) } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admins_availabilities_path }
          format.json { render json: { success: false, partial: render_to_string(partial: 'admins/availabilities/form', locals: { availability: @availability }, formats: [:html]) } }
        end
      end
    end

    def destroy
      @availability = Availability.find(params[:id])
      redirect_to admins_availabilities_path if @availability.destroy
    end

    private

    def availability_params
      params.require(:availability).permit(:start_date, :end_date, :available, :user_id)
    end

    def set_users
      @users = current_admin.users
    end

    def authorize_data_admin
      return unless params[:user_id].present?

      redirect_to('/401') unless current_admin.users.find_by(id: params[:user_id])
    end

    def filter_users_with_availabilities
      @users = @users.select { |user| user.availabilities.any? }
    end

    def filter_availabilities_by_user_id
      @availabilities = Availability.where(user_id: params[:user_id])
    end

    def respond_to_formats(partial_name, locals)
      respond_to do |format|
        format.html
        format.text { render(partial: "admins/availabilities/#{partial_name}", locals:, formats: [:html]) }
      end
    end
  end
end
