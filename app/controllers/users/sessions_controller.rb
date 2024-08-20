# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    include RackSessionsFix
    respond_to :json

    def new
      super
    end

    # @summary Login as User
    # @no_auth
    #
    # @request_body The user to be created. At least include an `email`. [User!]
    # @request_body_example basic user [Hash] {user: {email: "test@gmail.com", password: "azerty"}}
    def create
      super
    end

    def destroy
      user = current_user
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message! :notice, :signed_out if signed_out
      yield if block_given?
      if request.headers['Authorization'].present?
        jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
        current_api_user = User.find(jwt_payload['sub'])
      end
      if current_api_user && user
        render json: { message: 'Logged out successfully.' }, status: :ok
      else
        render json: { message: "Couldn't find an active session." }, status: :unauthorized
      end
    end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:role])
    # end

    private

    def respond_with(current_user, _opts = {})
      render json: {
        status: {
          data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
        }
      }, status: :ok
    end
  end
end
