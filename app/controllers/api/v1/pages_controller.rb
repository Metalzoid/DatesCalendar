module Api
  module V1
    class PagesController < ApplicationController
      def index
        api_version = Rails.configuration.x.api.version
        respond_to do |format|
          format.html { render "api/#{api_version}/pages/index" }
        end
      end
    end
  end
end
