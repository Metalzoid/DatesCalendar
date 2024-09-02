# app/controllers/admins/services_controller.rb
module Admins
  class ServicesController < Admins::AdminsPagesController
    before_action :authorize_data_admin, only: %i[index destroy]
    before_action :set_users, only: %i[index]

    def index
      filter_users_with_services
      @services = @users.flat_map(&:services).sort_by(&:id)
      @service = Service.new
      filter_services_by_user_id if params[:user_id].present? && params[:user_id] != 'none'
      respond_to_formats('services_infos', services: @services)
    end

    def create
      @service = Service.new(service_params)
      if @service.save
        respond_to_success_create(@service)
      else
        respond_to_errors_create(@service)
      end
    end

    def destroy
      @service = Service.find(params[:id])
      if params[:listed].present? && @service.destroy
        redirect_to "#{admins_services_url}?user_id=#{params[:user_id]}"
      elsif @service.destroy
        redirect_to admins_services_path
      end
    end

    private

    def service_params
      params.require(:service).permit(:title, :price, :time, :user_id)
    end

    def set_users
      @users = current_admin.users
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
