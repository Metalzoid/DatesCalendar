# frozen_string_literal: true

# AppointmentService Model
class AppointmentService < ApplicationRecord
  belongs_to :appointment
  belongs_to :service
end
