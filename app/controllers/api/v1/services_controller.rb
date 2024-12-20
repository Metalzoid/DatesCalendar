# frozen_string_literal: true
module Api
  module V1
    # Services controller
    class ServicesController < ApiController
      before_action :authorization!, only: %i[create update]
      before_action :set_service, only: %i[update]

      # @summary Returns the list of Services.
      # - Optionnal: Filter by seller ID.
      # - Time exprimed in minutes.
      # - URL exemple: /api/v1/services?seller_id=1
      # @response Services founded.(200) [Hash{message: String, data: Array<Hash{id: Integer, title: String, price: Float, time: Integer, user_id: Integer, enabled: Boolean}>}]
      # @response_example Services founded.(200) [{message: "Services founded.", data: [{id: 1, title: "Massage", price: 14.69, time: 30, user_id: 2, disabled: true}] }]
      # @response Services not founded.(404) [Hash{message: String}]
      # @response_example Services not founded.(404) [{message: "Services not founded."}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be Seller or Admin to perform this action.(403) [{message: "You need to be Seller or Admin to perform this action."}]
      # @tags services
      # @auth [bearer_jwt]
      def index
        @services = Service.by_admin(current_user.admin).where(disabled: false)
        @services = @services.where(user: params[:seller_id]) if params[:seller_id].present?
        @services_serialized = @services.map do |service|
          ServiceSerializer.new(service).serializable_hash.dig(:data, :attributes)
        end
        return render_success('Services founded.', @services_serialized, :ok) unless @services.empty?

        render_error('Services not founded.', :not_found)
      end

      # @summary Create a service.
      # - Only for seller or both role.
      # - Time exprimed in minutes.
      # @request_body The service to be created. [!Hash{service: Hash{ title: String, price: Float, time: Integer }}]
      # @request_body_example A complete Service. [Hash] {service: {title: 'Massage', price: 44.99, time: 30 }}
      # @response Service created.(201) [Hash{message: String, data: Hash{id: Integer, title: String, price: Float, time: Integer, user_id: Integer}}]
      # @response_example Service created.(201) [{message: "Service created.", data: {id: 1, title: "Massage", price: 14.69, time: 30, user_id: 2}}]
      # @response Can't create service.(422) [Hash{message: String, errors: Hash}]
      # @response_example Can't create service.(422) [{message: "Can't create service.", errors: {title: ["Can't be blank"]}}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be Seller or Admin to perform this action.(403) [{message: "You need to be Seller or Admin to perform this action."}]
      # @tags services
      # @auth [bearer_jwt]
      def create
        @service = Service.new(service_params)
        @service.user = current_user
        return render_success('Service created.', ServiceSerializer.new(@service).serializable_hash.dig(:data, :attributes), :created) if @service.save

        render_error("Can't create service.", @service.errors.messages, :unprocessable_entity)
      end

      # @summary Update a service.
      # - Time exprimed in minutes.
      # @request_body The service to be created. [!Hash{service: Hash{title: String, price: Float, time: Integer}}]
      # @request_body_example A complete Service. [Hash] {service: {title: 'Massage', price: 44.99, time: 30}}
      # @response Service updated.(200) [Hash{message: String, data: Hash{id: Integer, title: String, price: Float, time: Integer, user_id: Integer}}]
      # @response_example Service updated.(200) [{message: "Service updated.", data: {id: 1, title: "Massage", price: 14.69, time: 30, user_id: 2}}]
      # @response Can't update service.(422) [Hash{message: String, errors: Hash}]
      # @response_example Can't update service.(422) [{message: "Can't update service.", errors: {title: ["Can't be blank"]}}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be Seller or Admin to perform this action.(403) [{message: "You need to be Seller or Admin to perform this action."}]
      # @response Service {id} could not be found.(404) [Hash{message: String}]
      # @response_example Service {id} could not be found.(404)[{message: "Service 3 could not be found."}]
      # @tags services
      # @auth [bearer_jwt]
      def update
        return render_error("Can't update another user's service.", :forbidden) if current_user != @service.user

        return render_success('Service updated.', ServiceSerializer.new(@service).serializable_hash.dig(:data, :attributes), :ok) if @service.update(service_params)

        render_error("Can't update service.", @service.errors.messages, :unprocessable_entity)
      end

      private

      def service_params
        params.require(:service).permit(:title, :price, :time, :disabled)
      end

      def set_service
        @service = Service.find_by(id: params[:id])
        render json: { message: "Service #{params[:id]} could not be found." }, status: :not_found unless @service
      end

      def authorization!
        return if !current_admin.nil? || %w[seller both].include?(current_user.role)

        render json: { message: 'You need to be Seller or Admin to perform this action.' }, status: :forbidden
      end
    end
  end
end
