# frozen_string_literal: true

# Appointment Model
class Appointment < ApplicationRecord
  after_save :handle_availability_changes, if: :saved_change_to_status?
  after_commit :broadcast_appointments

  belongs_to :customer, class_name: 'User'
  belongs_to :seller, class_name: 'User'
  has_many :appointment_services, dependent: :destroy
  has_many :services, through: :appointment_services

  validates :start_date, presence: true, comparison: { greater_than: Time.now }
  validates :end_date, comparison: { greater_than: :start_date }
  validates :comment, presence: true, length: { maximum: 500 }
  validates :customer_id, presence: true
  validates :seller_id, presence: true
  validate :check_availability, if: :new_record?

  enum :status, [:hold, :accepted, :finished, :canceled, :refused]

  scope :by_admin, ->(admin) { joins(:customer, :seller).merge(User.by_admin(admin)) }

  private

  def transform_date(date)
    I18n.l(date, format: :custom)
  end

  # Validation simplifiée déléguée au service
  def check_availability
    availability_service = AppointmentAvailabilityService.new(self)
    availability_service.validate_appointment_availability
  end

  # Callback simplifié qui délègue aux services
  def handle_availability_changes
    availability_service = AppointmentAvailabilityService.new(self)
    previous_status = saved_change_to_status&.first
    current_status = saved_change_to_status&.last || status

    case current_status
    when 'accepted'
      availability_service.handle_appointment_acceptance
    else
      # Si on passe d'un statut "accepted" à autre chose, on restaure la disponibilité
      availability_service.handle_appointment_status_change_from_accepted(previous_status) if previous_status == 'accepted'
    end
  end

  def broadcast_appointments
    return if Rails.env.test?

    NewAppointmentsChannel.send_appointments(seller)
    NewAppointmentsChannel.send_appointments(customer)
  end
end
