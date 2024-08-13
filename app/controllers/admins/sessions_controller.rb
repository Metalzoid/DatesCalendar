# frozen_string_literal: true

module Admins
  class SessionsController < Devise::SessionsController
    include RackSessionsFix
    # before_action :configure_sign_in_params, only: [:create]

    # GET /resource/sign_in
    def new
      respond_to do |format|
        format.html { super }
      end
    end

    # POST /resource/sign_in
    def create
      self.resource = warden.authenticate!(auth_options)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?

      respond_to do |format|
        format.json do
          render json: {
            message: "Logged in successfully.",
            data: AdminSerializer.new(current_admin).serializable_hash[:data][:attributes]
          }, status: :ok
        end

        format.html do
          redirect_to after_sign_in_path_for(resource)
        end
      end
    end

    # DELETE /resource/sign_out
    def destroy
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message! :notice, :signed_out if signed_out
      yield if block_given?
      respond_to_on_destroy
    end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end
    # private

    # def respond_with(current_admin, _opts = {})
    #   respond_to do |format|
    #     # format.json { render json: { message: "Logged in successfully.",
    #     #                 data: AdminSerializer.new(current_admin).serializable_hash[:data][:attributes]
    #     #               }, status: :ok }
    #     format.html
    #   end
    # end
    #

    def respond_to_on_destroy
      if request.headers['Authorization'].present?
        jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
        current_api_admin = Admin.find(jwt_payload['sub'])
      end
      if current_api_admin
        respond_to do |format|
          format.json { render json: { message: 'Logged out successfully.' }, status: :ok }
        end
      else
        respond_to do |format|
          format.json { render json: { message: "Couldn't find an active session." }, status: :unauthorized }
          format.html { redirect_to new_admin_session_path }
        end

      end
    end
  end
end
