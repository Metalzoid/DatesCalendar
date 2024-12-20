# frozen_string_literal: true

module Admins
  # Devise sessions controller for admin Class.
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
      sign_in = sign_in(resource_name, resource)
      yield resource if block_given?

      if sign_in
        respond_to_successful_sign_in
      else
        respond_to_failed_sign_in
      end
    end

    # DELETE /resource/sign_out
    def destroy
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message!(:notice, :signed_out) if signed_out
      yield if block_given?
      respond_to_on_destroy
    end

    private

    def respond_to_successful_sign_in
      respond_to do |format|
        format.json do
          render json: { message: 'Logged in successfully.',
                         data: AdminSerializer.new(current_admin).serializable_hash.dig(:data, :attributes) }, status: :ok
        end
        format.html do
          set_flash_message!(:notice, :signed_in)
          redirect_to after_sign_in_path_for(resource)
        end
      end
    end

    def respond_to_failed_sign_in
      respond_to do |format|
        format.json { render json: { message: 'Logged in unsuccessfully.' }, status: :bad_request }
        format.html { render :new, status: :unprocessable_entity }
      end
    end

    def respond_to_on_destroy
      current_api_admin = find_current_api_admin

      if current_api_admin
        respond_to_successful_sign_out
      else
        respond_to_failed_sign_out
      end
    end

    def find_current_api_admin
      return unless request.headers['Authorization'].present?

      jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
      Admin.find(jwt_payload['sub'])
    end

    def respond_to_successful_sign_out
      respond_to do |format|
        format.json { render json: { message: 'Logged out successfully.' }, status: :ok }
        format.html { redirect_to root_path }
      end
    end

    def respond_to_failed_sign_out
      respond_to do |format|
        format.json { render json: { message: "Couldn't find an active session." }, status: :unauthorized }
        format.html { redirect_to root_path }
      end
    end
  end
end
