# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    include RackSessionsFix
    respond_to :json

    def new
      super
    end

    # @summary Login as User
    # - Return the JWT token in the headers.
    # @request_body The user login. At least include an `email`. [Hash!] {user: {email: String, password: String}}
    # @request_body_example basic user [Hash] {user: {email: "test@gmail.com", password: "azerty"}}
    # @response Invalid Email or password.(401) [Hash] {error: String}
    # @response Logged in Successfully.(200) [Hash] {message: String, data: Hash}
    # @tags Users
    # @no_auth
    def create
      super
    end

    # @summary Logout as User
    # @parameter Authorization(header) [String!] The Authorization JWT token.
    # @response Couldn't find an active session.(401) [Hash] {message: String}
    # @response Logged out Successfully.(200) [Hash] {message: String}
    # @tags Users
    # @no_auth
    def destroy
      user = current_user
      sign_out(resource_name)
      yield if block_given?
      if request.headers['Authorization'].present?
        jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
        current_api_user = User.find(jwt_payload['sub'])
      end
      return render json: { message: 'Logged out Successfully.' }, status: :ok if current_api_user && user

      render json: { message: "Couldn't find an active session." }, status: :unauthorized

    end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:role])
    # end

    private

    def respond_with(current_user, _opts = {})
      render json: {
        message: "Logged in Successfully.",
        data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
      }, status: :ok
    end
  end
end
