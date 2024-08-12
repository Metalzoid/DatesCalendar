# frozen_string_literal: true

module Admins
  class SessionsController < Devise::SessionsController
    include RackSessionsFix
    # before_action :configure_sign_in_params, only: [:create]

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    # def create
    #   super do |resource|
    #     if resource.persisted?
    #       token = request.env['warden-jwt_auth.token']
    #       response.headers['Authorization'] = "Bearer #{token}"
    #     end
    #   end
    # end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end
    # private

    def respond_with(current_admin, _opts = {})
      if current_admin
        respond_to do |format|
          format.json { render json: {
            message: "Logged in successfully.",
            data: AdminSerializer.new(current_admin).serializable_hash[:data][:attributes]
          }, status: :ok }
          format.html { super }
        end
      else
        respond_to do |format|
          format.json { render_error('Error. You need to be authentificated to perform this action.', :unauthorized) }
          format.html { super }
        end
      end
    end

    def respond_to_on_destroy
      if request.headers['Authorization'].present?
        jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
        current_admin = Admin.find(jwt_payload['sub'])
      end
      if current_admin
        respond_to do |format|
          format.json { render_success('Logged out successfully.', { data: AdminSerializer.new(current_admin).serializable_hash[:data][:attributes] }, :ok ) }
          format.html { redirect_to api_v1_admin_root_path }
        end
      else
        respond_to do |format|
          format.json { render_error("Couldn't find an active session.", :unauthorized) }
          format.html { redirect_to new_admin_session_path }
        end
      end
    end
  end
end
