# frozen_string_literal: true

# Service pour gérer les disponibilités lors des changements de statut des rendez-vous
class AppointmentAvailabilityService
  def initialize(appointment)
    @appointment = appointment
    @availability_service = AvailabilityManagementService.new(@appointment.seller)
  end

  # Appelé quand un rendez-vous devient "accepted"
  def handle_appointment_acceptance
    return unless @appointment.accepted?

    @availability_service.create_unavailability_for_appointment(
      @appointment.start_date,
      @appointment.end_date
    )
  end

  # Appelé quand un rendez-vous "accepted" change vers un autre statut
  def handle_appointment_status_change_from_accepted(previous_status)
    return unless previous_status == 'accepted'

    @availability_service.restore_availability_after_appointment_cancellation(
      @appointment.start_date,
      @appointment.end_date
    )
  end

  # Vérifie si un rendez-vous peut être créé (disponibilité suffisante)
  def validate_appointment_availability
    return true unless @appointment.new_record?

    available_slot = find_available_slot

    if available_slot
      true
    else
      @appointment.errors.add(
        :availability,
        'Les dates de début et de fin doivent être incluses dans un créneau de disponibilité.'
      )
      false
    end
  end

  private

  def find_available_slot
    @appointment.seller.availabilities
                     .where(available: true)
                     .find do |availability|
      @appointment.start_date >= availability.start_date &&
        @appointment.end_date <= availability.end_date
    end
  end
end
