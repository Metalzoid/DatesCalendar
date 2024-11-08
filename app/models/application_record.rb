# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  protected

  def self.group_by_day(admin)
    items = self.by_admin(admin)
    grouped_items = items.group_by { |item| item.created_at.to_date }
    count_by_day = grouped_items.transform_values(&:count)
    last_week_dates = (6.days.ago.to_date..Date.today).to_a
    formatted_hash = last_week_dates.map { |date| [date, 0] }.to_h
    formatted_hash.merge!(count_by_day)
    formatted_hash
  end

  def send_data_cable
  #   appointments = self.user.appointments.map do |appointment|
  #     AppointmentSerializer.new(appointment).serializable_hash[:data][:attributes]
  #   end
  #   availabilities = self.user.availabilities.map do |availability|
  #     AvailabilitySerializer.new(availability).serializable_hash[:data][:attributes]
  #   end
  #   services = self.user.services.map do |service|
  #     ServiceSerializer.new(service).serializable_hash[:data][:attributes]
  #   end
  #   data = {
  #     user: UserSerializer.new(self.user).serializable_hash[:data][:attributes],
  #     appointments:,
  #     availabilities:,
  #     services:
  # }
  #   ActionCable.server.broadcast("all_data_user#{self.user_id}", data)
    AllDatasChannel.send_all_datas(self.user)
  end

  private

end
