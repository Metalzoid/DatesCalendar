# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AdminPagesController < ApplicationController
        before_action :authenticate_admin!
        def index
          api_version = Rails.configuration.x.api.version
          respond_to do |format|
            format.html { render "api/#{api_version}/admin/pages/index" }
          end
        end

        private

        def authenticate_admin!
          redirect_to new_admin_session_path if current_admin.nil?
        end
      end
    end
  end
end
