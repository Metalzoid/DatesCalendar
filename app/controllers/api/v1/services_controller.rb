# frozen_string_literal: true

module Api
  module V1
    # Services controller
    class ServicesController < ApiController
      before_action :authorization!, only: %i[create update destroy]
      before_action :set_service, only: %i[update destroy]

      # @summary Returns the list of Services.
      # - Optionnal: Filter by seller ID.
      # - URL exemple: /api/v1/services?seller_id=1
      # @response Services founded.(200) [Hash{message: String, data: Hash}]
      # @response Services not founded.(404) [Hash{message: String}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @tags services
      # @auth [bearer_jwt]
      def index
        @services = Service.by_admin(current_user.admin)
        @services = @services.where(user: params[:seller_id]) if params[:seller_id]
        return render_success('Services founded.', @services, :ok) unless @services.empty?

        render_error('Services not founded.', :not_found)
      end

      # @summary Create a service.
      # - Only for seller or both role.
      # - Time is minutes only.
      # @request_body The service to be created. [Hash{service: {title: String, price: Float, time: Integer}}]
      # @request_body_example A complete Service. [Hash{service: {title: 'Massage', price: 44.99, time: 30}}]
      # @response Service created.(200) [Hash{message: String, data: Hash}]
      # @response Can't create service.(422) [Hash{message: String}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @tags services
      # @auth [bearer_jwt]
      def create
        @service = Service.new(service_params)
        @service.user = current_user
        return render_success('Service created.', @service, :created) if @service.save

        render_error("Can't create service. Error: #{@service.errors.messages}", :unprocessable_entity)
      end

      # @summary Update a service.
      # - Time is minutes only.
      # @request_body The service to be created. [Hash{service: {title: String, price: Float, time: Integer}}]
      # @request_body_example A complete Service. [Hash{service: {title: 'Massage', price: 44.99, time: 30}}]
      # @response Service updated.(200) [Hash{message: String, data: Hash}]
      # @response Can't update service.(422) [Hash{message: String}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response Service {id} could not be found.(404) [Hash{message: String}]
      # @tags services
      # @auth [bearer_jwt]
      def update
        return render_success('Service updated.', @service, :ok) if @service.update(service_params)

        render_error("Can't update service. Error: #{@service.errors.messages}", :unprocessable_entity)
      end

      # @summary Destroy a service.
      # @response Service destroyed.(200) [Hash{message: String, data: Hash}]
      # @response Can't destroy service.(422) [Hash{message: String}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response Service {id} could not be found.(404) [Hash{message: String}]
      # @tags services
      # @auth [bearer_jwt]
      def destroy
        return render_success('Service destroyed.', @service, :ok) if @service.destroy

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
        return if !current_admin.nil? || ['seller', 'both'].include?(current_user.role)

        render json: { message: 'You need to be Seller or Admin to perform this action.' }, status: :forbidden
      end
    end
  end
end
