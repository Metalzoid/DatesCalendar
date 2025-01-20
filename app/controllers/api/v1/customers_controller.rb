module Api
  module V1
    class CustomersController < ApplicationController
      before_action :authorization!
      # @summary Returns the list of Customers.
      # @response Customers founded.(200) [Hash{message: String, data: Array<Hash{id: Integer, email: String, firstname: String, lastname: String, company: String, role: String, phone_number: String}>}]
      # @response_example Customers founded.(200) [{message: "Services founded.", data: [{id: 1, email: "test@test.fr", firstname: "Firstname", lastname: "Lastname", company: "Company name", role: "seller", phone_number: "01 02 03 04 05"}] }]
      # @response Customers not founded.(404) [Hash{message: String}]
      # @response_example Customers not founded.(404) [{message: "Customers not founded."}]
      # @response You need to be Seller or Admin to perform this action.(403) [Hash{message: String}]
      # @response_example You need to be Seller or Admin to perform this action.(403) [{message: "You need to be Seller or Admin to perform this action."}]
      # @tags customers
      # @auth [bearer_jwt]
      def index
        @customers = current_user.appointments.map(&:customer).uniq(&:id).map { |customer| UserSerializer.new(customer).serializable_hash[:data][:attributes] }
        return render_success('Customers founded.', @customers, :ok) unless @customers.nil?

        render_error('Customers not founded.', :not_found)
      end

      private

      def authorization!
        return if !current_admin.nil? || %w[seller both].include?(current_user.role)

        render json: { message: 'You need to be Seller or Admin to perform this action.' }, status: :forbidden
      end
    end
  end
end
