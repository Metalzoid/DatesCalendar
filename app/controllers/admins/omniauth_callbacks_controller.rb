# frozen_string_literal: true

module Admins
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # You should configure your model like this:
    # devise :omniauthable, omniauth_providers: [:twitter]
    #
    def github
      @admin = Admin.create_from_provider_data(request.env['omniauth.auth'])
      if @admin.persisted?
          sign_in_and_redirect @admin
          set_flash_message(:notice, :success, kind: 'Github') if is_navigational_format?
      else
          flash[:error]='There was a problem signing you in through Github. Please register or try signing in later.'
          redirect_to new_admin_registration_path
      end
    end

    def google_oauth2
      @admin = Admin.create_from_provider_data(request.env['omniauth.auth'])
      if @admin.persisted?
           sign_in_and_redirect @admin
           set_flash_message(:notice, :success, kind: 'Google') if is_navigational_format?
      else
           flash[:error]='There was a problem signing you in through Google. Please register or try signing in later.'
           redirect_to new_admin_registration_path
      end
   end

    def failure
        flash[:error] = 'There was a problem signing you in. Please register or try signing in later.'
        redirect_to new_user_registration_path
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
