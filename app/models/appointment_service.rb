# frozen_string_literal: true

class AppointmentService < ApplicationRecord
  belongs_to :appointment
  belongs_to :service
end
