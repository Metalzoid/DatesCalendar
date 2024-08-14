# frozen_string_literal: true

module Api
  module V1
    # Services controller
    class ServicesController < ApiController
      before_action :authenticate_user!
      before_action :authorization!, only: %i[create update destroy]
      before_action :set_service, only: %i[update destroy]

      def index
        @services = Service.all
        return render_success('Services founded.', { data: @services }, :ok) unless @services.empty?

        render_error('Services not founded.', :not_found)
      end

      def create
        @service = Service.new(service_params)
        @service.user = current_user
        return render_success('Service created.', { data: @service }, :created) if @service.save

        render_error("Can't create service. #{@service.errors.messages}", :unprocessable_entity)
      end

      def update
        return render_success('Service updated.', { data: @service }, :ok) if @service.update(service_params)

        render_error("Can't update service. #{@service.errors.messages}", :unprocessable_entity)
      end

      def destroy
        return render_success('Service destroyed.', { data: @service }, :ok) if @service.destroy

        render_error("Can't destroy service. #{@service.errors.messages}", :unprocessable_entity)
      end

      private

      def service_params
        params.require(:service).permit(:title, :price, :time)
      end

      def set_service
        @service = Service.find_by(id: params[:id])
        render json: { message: "Service #{params[:id]} could not be found." }, status: :not_found unless @service
      end

      def authorization!
        return if !current_admin.nil? || ['seller', 'all'].include?(current_user.role)

        render json: { message: 'You need to be Vendor or Admin to perform this action.' }, status: :forbidden
      end
    end
  end
end
