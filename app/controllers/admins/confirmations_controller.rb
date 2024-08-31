# frozen_string_literal: true

module Admins
  # Devise confirmation controller for admin class
  class ConfirmationsController < Devise::ConfirmationsController
    def success
      render 'devise/confirmations/success'
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
