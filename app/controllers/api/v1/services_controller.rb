# frozen_string_literal: true

module Api
  module V1
    # Services controller
    class ServicesController < ApiController
      before_action :authenticate_user!
      before_action :authorization!, only: %i[create update destroy]
      before_action :set_service, only: %i[update destroy]

      def index
        render json: Service.all
      end

      def create
        @service = Service.new(service_params)
        @service.user = current_user
        if @service.save
          render json: { message: 'Service created.' }, status: :created
        else
          render json: { errors: @service.errors.messages }, status: :unprocessable_entity
        end
      end

      def update
        if @service.update(service_params)
          render json: { message: 'Service updated.' }, status: :ok
        else
          render json: { errors: @service.errors.message }, status: :unprocessable_entity
        end
      end

      def destroy
        if @service.destroy
          render json: { message: "Service #{@service.id} has been deleted" }, status: :ok
        else
          render json: { errors: @service.errors.messages }, status: :unprocessable_entity
        end
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
        return if !current_admin.nil? || current_user.role == 'seller'

        render json: { message: 'You need to be Vendor or Admin to perform this action.' }, status: :forbidden
      end
    end
  end
end
