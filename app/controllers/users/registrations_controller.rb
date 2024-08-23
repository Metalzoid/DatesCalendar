# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    # @summary Register new User
    # - Necessary Admin API KEY.
    # - Role can be: seller, customer, both.
    # - Password minimum length: 6 chars.
    # - Optionnal: company.
    # @parameter APIKEY(header) [String!] The admin APIKEY.
    # @request_body The user informations. At least include an `email`. [Hash!] {user: {email: String, password: String, firstname: String, lastname: String, company: String, role: String}}
    # @request_body_example basic user [Hash] {user: {email: "test@gmail.com", password: "azerty", firstname: "Pedro", lastname: "Pedro", role: "seller"}}
    # @response Logged in Successfully.(200) [Hash] {message: String, data: Hash}
    # @response User couldn't be created successfully. Admin must exist and Admin can't be blank.(422) [Hash] {message: String}
    # @tags Users
    def create
      @user = build_resource(sign_up_params)
      if request.headers['APIKEY'].present?
        current_api_admin = ApiKey.find_by(api_key: request.headers['APIKEY']).admin
        @user.admin = current_api_admin
      end
      @user.save
      yield resource if block_given?
      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    # GET /resource/edit
    # def edit
    #   super
    # end

    # PUT /resource
    # def update
    #   super
    # end

    # DELETE /resource
    # def destroy
    #   super
    # end

    # GET /resource/cancel
    # Forces the session data which is usually expired after sign
    # in to be expired now. This is useful if the user wants to
    # cancel oauth signing in/up in the middle of the process,
    # removing all OAuth session data.
    # def cancel
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_up_params
    #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
    # end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_account_update_params
    #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
    # end

    # The path used after sign up.
    # def after_sign_up_path_for(resource)
    #   super(resource)
    # end

    # The path used after sign up for inactive accounts.
    # def after_inactive_sign_up_path_for(resource)
    #   super(resource)
    # end
    include RackSessionsFix
    respond_to :json

    private

    def respond_with(current_user, _opts = {})
      if resource.persisted?
        render json: {
          message: 'Signed up successfully.',
          data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
        }, status: :ok
      else
        render json: {
          message: "User couldn't be created successfully. #{current_user.errors.full_messages.to_sentence}"
        }, status: :unprocessable_entity
      end
    end
  end
end
