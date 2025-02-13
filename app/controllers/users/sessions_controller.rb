# frozen_string_literal: true

module Users
  # Sessions controller users
  class SessionsController < Devise::SessionsController
    include RackSessionsFix
    respond_to :json

    # @summary Get current user informations
    # @response Data of the current user connected.(200) [Hash{message: String, data: Hash{id: Integer, email: String, firstname: String, lastname: String, company: String, role: String }}]
    # @response_example Data of the current user connected.(200) [{message: "Data of the current user connected.", data: {id: 2, email: "test@gmail.com", firstname: "Pedro", lastname: "Pedro", company: "", role: "seller"}}]
    # @response Couldn't find an active session.(401) [Hash{message: String}]
    # @response_example Couldn't find an active session.(401) [{message: "Couldn't find an active session."}]
    # @tags Users
    # @auth [bearer_jwt]
    def new
      yield if block_given?
      if request.headers['Authorization'].present?
        jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
        current_api_user = User.find(jwt_payload['sub'])
      end
      return render json: { message: 'Data of the current user connected.', data: UserSerializer.new(current_api_user).serializable_hash.dig(:data, :attributes) }, status: :ok if current_api_user && current_user

      render json: { message: "Couldn't find an active session." }, status: :unauthorized
    end

    # @summary Login as User
    # - Return the JWT token in the headers.
    # @request_body The user login. At least include an `email`. [!Hash{user: Hash{email: String, password: String}}]
    # @request_body_example basic user [Hash] {user: {email: "test@gmail.com", password: "azerty"}}
    # @response Invalid Email or password.(401) [Hash{error: String}]
    # @response_example Invalid Email or password.(401) [{error: "Invalid Email or password."}]
    # @response Logged in Successfully.(200) [Hash{message: String, data: Hash{user: Hash{id: Integer, email: String, firstname: String, lastname: String, company: String, role: String}}}]
    # @response_example Logged in Successfully.(200) [{message: "Logged in Successfully.", data: {user: {id: 2, email: "test@gmail.com", firstname: "Pedro", lastname: "Pedro", company: "", role: "seller"}}}]
    # @tags Users
    # @no_auth
    def create
      self.resource = warden.authenticate!(auth_options)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end

    # @summary Logout as User
    # @response Couldn't find an active session.(401) [Hash{message: String}]
    # @response_example Couldn't find an active session.(401) [{message: "Couldn't find an active session."}]
    # @response Logged out Successfully.(200) [Hash{message: String}]
    # @response_example Logged out Successfully.(200) [{message: "Logged out Successfully.(200)"}]
    # @tags Users
    # @auth [bearer_jwt]
    def destroy
      return render json: { message: "User's cookie required !" }, status: :unauthorized unless cookies.signed["user.id"]
      return render json: { message: 'JWT token required !' }, status: :unauthorized unless request.headers["Authorization"].present?

      if request.headers['Authorization'].present? && cookies.signed["user.id"] == current_user.id
        jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
        current_api_user = User.find(jwt_payload['sub'])
        return render json: { message: 'User not found with this JWT token.' }, status: :not_found unless current_api_user
      end

      return render json: { message: 'JWT token already revoked!' } if current_api_user.jwt_revoked?(jwt_payload)

      signed_out = sign_out(resource_name)
      current_api_user.revoke_jwt(jwt_payload) if signed_out

      render json: { message: 'Logged out Successfully.' }, status: :ok if signed_out
    end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:role])
    # end

    private

    def verify_signed_out_user; end

    def respond_with(current_user, _opts = {})
      render json: {
        message: 'Logged in Successfully.',
        data: { user: UserSerializer.new(current_user).serializable_hash.dig(:data, :attributes) }
      }, status: :ok
    end
  end
end
