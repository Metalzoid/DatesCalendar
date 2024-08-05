module Api
  module V1
    class AdminsessionController < ApplicationController
      before_action :authenticate_admin!
      def avo
        redirect_to "/avo"
      end

      private

      def authenticate_admin!
        redirect_to new_api_v1_admin_session_path if current_api_v1_admin.nil?
      end
    end
  end
end
