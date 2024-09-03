# frozen_string_literal: true
require 'pry-byebug'
module Users
  class RegistrationsController < Devise::RegistrationsController
    # @summary Register new User
    # - Necessary: Admin API KEY.
    # - Role can be: seller, customer, both.
    # - Password minimum length: 6 chars.
    # - Optionnal: company.
    # @parameter APIKEY(header) [!String] Your admin APIKEY. <button onclick="setApikey(event)" type="button" class="m-btn primary thin-border" >Set DEMO API KEY</button>
    # @request_body The user informations. At least include an `email`. [!Hash{user: Hash{email: String, password: String, firstname: String, lastname: String, company: String, role: String}}]
    # @request_body_example basic user [Hash] {user: {email: "test@gmail.com", password: "azerty", firstname: "Pedro", lastname: "Pedro", role: "seller"}}
    # @response Logged in Successfully.(200) [Hash{message: String, data: Hash{user: Hash{id: Integer, email: String, firstname: String, lastname: String, company: String, role: String}}}]
    # @response_example Logged in Successfully.(200) [{message: "Logged in Successfully.", data: {user: {id: 2, email: "test@gmail.com", firstname: "Pedro", lastname: "Pedro", company: "", role: "seller"}}}]
    # @response User couldn't be created successfully. Admin must exist and Admin can't be blank.(422) [Hash{message: String}]
    # @response_example User couldn't be created successfully. Admin must exist and Admin can't be blank.(422) [{message: "User couldn't be created successfully. Admin must exist and Admin can't be blank."}]
    # @tags Users
    def create
      @user = build_resource(sign_up_params)
      if request.headers['APIKEY'].present?
        headers = request.headers['APIKEY']
        if headers.include?(',')
          api_key = headers.split(',').first
          current_api_admin = ApiKey.find_by(api_key:).admin
        else
          current_api_admin = ApiKey.find_by(api_key: headers).admin
        end
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

    # @summary Edit a User
    # - Required: current_password
    # @request_body The user informations. At least include an `email`. [!Hash{user: Hash{email: String, current_password: String, password: String, password_confirmation: String, firstname: String, lastname: String, company: String, role: String}}]
    # @request_body_example basic user [Hash] {user: {email: "test2@gmail.com", current_password: "azerty", role: "both"}}
    # @response User has been updated.(200) [Hash{message: String, data: Hash{user: Hash{id: Integer, email: String, firstname: String, lastname: String, company: String, role: String}}}]
    # @response_example User has been updated.(200) [{message: "User has been updated.", data: {user: {id: 2, email: "test2@gmail.com", firstname: "Pedro", lastname: "Pedro", company: "", role: "both"}}}]
    # @response Bearer JWT Token required !(401) [Hash{message: String}]
    # @response_example Bearer JWT Token required !(401) [{message: "Bearer JWT Token required !"}]
    # @response User has not been updated.(422) [Hash{message: String}]
    # @response_example User has not been updated.(422) [{message: "User has not been updated. => error message"}]
    # @tags Users
    # @auth [bearer_jwt]
    def update
      return render json: {message: "Bearer JWT Token required !"}, status: :unauthorized unless request.headers['Authorization'].present?
      if request.headers['Authorization'].present?
        jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
        current_api_user = User.find(jwt_payload['sub'])
      end
      self.resource = current_api_user
      prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

      resource_updated = update_resource(resource, account_update_params)
      yield resource if block_given?
      if resource_updated
        set_flash_message_for_update(resource, prev_unconfirmed_email)
        bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

        render json: {message: "User has been updated.", data: {user: UserSerializer.new(self.resource).serializable_hash[:data][:attributes]}}, status: :ok
      else
        clean_up_passwords resource
        set_minimum_password_length
        render json: {message: "User has not been updated. #{self.resource.errors.messages}"}, status: :unprocessable_entity
      end
    end


    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_up_params
    #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
    # end

    # If you have extra params to permit, append them to the sanitizer.
    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
    end

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
