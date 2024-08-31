# frozen_string_literal: true

module Admins
  # AdminPages Controller
  class AdminsPagesController < ApplicationController
    def index
      @users = current_admin.users
      @availabilities = @users.flat_map(&:availabilities)
      @appointments = @users.flat_map(&:appointments)
      @services = @users.flat_map(&:services)
      @users_charts = User.group_by_day(current_admin)
      @services_charts = Service.group_by_day(current_admin)
      @availabilities_charts = Availability.group_by_day(current_admin)
      @appointments_charts = Appointment.group_by_day(current_admin)
    end

    def authorize_data_admin
      return unless params[:user_id].present?

      redirect_to('/401') unless current_admin.users.find_by(id: params[:user_id]) || params[:user_id] == 'none'
    end

    def respond_to_success_create(model)
      respond_to do |format|
        format.html { redirect_to "admins_#{model.class.name.downcase.pluralize}_path" }
        format.json do
          render json: {
            success: true,
            partial: render_to_string(partial: "admins/#{model.class.name.downcase.pluralize}/#{model.class.name.downcase}",
                                      locals: { model.class.name.downcase.to_sym => model }, formats: [:html]),
            form: render_to_string(partial: "admins/#{model.class.name.downcase.pluralize}/form",
                                   locals: { model.class.name.downcase.to_sym => model.class.new }, formats: [:html])
          }
        end
      end
    end

    def respond_to_errors_create(model)
      respond_to do |format|
        format.html { redirect_to "admins_#{model.class.name.downcase.pluralize}_path" }
        format.json do
          render json: {
            success: false,
            error: model.errors.full_messages.join(', '),
            partial: render_to_string(partial: "admins/#{model.class.name.downcase.pluralize}/form",
                                      locals: { model.class.name.downcase.to_sym => model },
                                      formats: [:html])
          }
        end
      end
    end
  end
end
