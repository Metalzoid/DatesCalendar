# app/controllers/admins/services_controller.rb
module Admins
  class ServicesController < ApplicationController
    before_action :authorize_data_admin, only: %i[index destroy]
    before_action :set_users, only: %i[index]

    def index
      filter_users_with_services
      @services = @users.flat_map(&:services)
      @service = Service.new

      return unless params[:user_id].present? && @services.any?

      filter_services_by_user_id
      respond_to_formats('services_infos', services: @services)
    end

    def create
      @service = Service.new(service_params)
      if @service.save
        respond_to do |format|
          format.html { redirect_to admins_services_path }
          format.json { render json: { success: true, partial: render_to_string(partial: 'admins/services/service', locals: { service: @service }, formats: [:html]) } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admins_services_path }
          format.json { render json: { success: false, partial: render_to_string(partial: 'admins/services/form', locals: { service: @service }, formats: [:html]) } }
        end
      end
    end

    def destroy
      @service = Service.find(params[:id])
      redirect_to admins_services_path if @service.destroy
    end

    private

    def service_params
      params.require(:service).permit(:title, :price, :time, :user_id)
    end

    def set_users
      @users = current_admin.users
    end

    def authorize_data_admin
      return unless params[:user_id].present?

      redirect_to('/401') unless current_admin.users.find_by(id: params[:user_id])
    end

    def filter_users_with_services
      @users = @users.select { |user| user.services.any? }
    end

    def filter_services_by_user_id
      @services = Service.where(user_id: params[:user_id])
    end

    def respond_to_formats(partial_name, locals)
      respond_to do |format|
        format.html
        format.text { render(partial: "admins/services/#{partial_name}", locals:, formats: [:html]) }
      end
    end
  end
end
