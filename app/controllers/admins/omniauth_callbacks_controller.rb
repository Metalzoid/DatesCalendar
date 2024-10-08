# frozen_string_literal: true

module Admins
  # Omniauth callbacks controller (using google oauth2)
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # You should configure your model like this:
    # devise :omniauthable, omniauth_providers: [:twitter]
    def google_oauth2
      @admin = Admin.from_omniauth(request.env['omniauth.auth'])

      if @admin.persisted?
        handle_successful_authentication
      else
        handle_failed_authentication
      end
    end

    def failure
      flash[:error] = 'There was a problem signing you in. Please register or try signing in later.'
      redirect_to new_user_registration_path
    end

    private

    def handle_successful_authentication
      sign_in_and_redirect @admin, event: :authentication
      set_flash_message(:notice, :success, kind: 'Google') if is_navigational_format?
    end

    def handle_failed_authentication
      session['devise.google_data'] = request.env['omniauth.auth'].except(:extra)
      redirect_to new_admin_registration_url, alert: @admin.errors.full_messages.join("\n")
    end

    # You should also create an action method in this controller like this:
    # def twitter
    # end

    # More info at:
    # https://github.com/heartcombo/devise#omniauth

    # GET|POST /resource/auth/twitter
    # def passthru
    #   super
    # end

    # GET|POST /users/auth/twitter/callback
    # def failure
    #   super
    # end

    # protected

    # The path used when OmniAuth fails
    # def after_omniauth_failure_path_for(scope)
    #   super(scope)
    # end
  end
end
