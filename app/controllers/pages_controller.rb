# frozen_string_literal: true

# Pages controller
class PagesController < ApplicationController
  def index
    respond_to do |format|
      format.html { render "api/v1/pages/index" }
    end
  end
end
