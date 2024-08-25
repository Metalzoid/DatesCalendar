# frozen_string_literal: true

module Admins
  class ConfirmationsController < Devise::ConfirmationsController

    # GET /resource/confirmation/new
    # def new
    #   super
    # end

    # POST /resource/confirmation
    # def create
    #   super
    # end

    # GET /resource/confirmation?confirmation_token=abcdef
    # def show
    #   super
    # end

    # def show
    #   super do |resource|
    #     if resource.errors.empty?
    #       sign_in(resource)
    #       return redirect_to confirmation_success_path
    #     end
    #   end
    # end

    def success
      render "devise/confirmations/success"
    end
    protected

    # The path used after resending confirmation instructions.
    # def after_resending_confirmation_instructions_path_for(resource_name)
    #   super(resource_name)
    # end

    # The path used after confirmation.
    def after_confirmation_path_for(_resource_name, _resource)
      confirmation_success_path
    end
  end
end
