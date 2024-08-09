# frozen_string_literal: true

class AppointmentService < ApplicationRecord
  belongs_to :appointment
  belongs_to :service

  after_commit :update_price

  private

  def update_price
    Appointment.all.each(&:update_price)
  end
end
