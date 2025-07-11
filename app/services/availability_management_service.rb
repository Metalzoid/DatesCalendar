# frozen_string_literal: true

# Service principal pour gérer les disponibilités et indisponibilités
class AvailabilityManagementService
  def initialize(user)
    @user = user
  end

  # Crée une indisponibilité pour un rendez-vous accepté
  def create_unavailability_for_appointment(start_date, end_date)
    return unless valid_time_range?(start_date, end_date)

    availability_to_split = find_availability_covering_range(start_date, end_date)
    return unless availability_to_split&.available?

    split_availability_for_unavailability(availability_to_split, start_date, end_date)
  end

  # Restaure les disponibilités quand un rendez-vous accepté est annulé
  def restore_availability_after_appointment_cancellation(start_date, end_date)
    return unless valid_time_range?(start_date, end_date)

    merge_adjacent_availabilities(start_date, end_date)
  end

  # Sauvegarde une disponibilité en gérant les chevauchements
  def save_availability_with_overlap_handling(availability)
    return { success: false, errors: availability.errors } unless availability.valid?

    ActiveRecord::Base.transaction do
      overlap_service = AvailabilityOverlapService.new(availability)
      resulting_availabilities = overlap_service.call

      resulting_availabilities.each do |av|
        av.skip_validation = true
        av.save!
      end

      { success: true, availabilities: resulting_availabilities }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors }
  end

  private

  def valid_time_range?(start_date, end_date)
    start_date.present? && end_date.present? && start_date < end_date
  end

  def find_availability_covering_range(start_date, end_date)
    @user.availabilities.find_by(
      'start_date <= ? AND end_date >= ? AND available = ?',
      start_date, end_date, true
    )
  end

  def split_availability_for_unavailability(availability, start_date, end_date)
    ActiveRecord::Base.transaction do
      availabilities_to_create = []

      # Partie avant l'indisponibilité
      if availability.start_date < start_date
        availabilities_to_create << build_availability(
          availability.start_date, start_date, true
        )
      end

      # L'indisponibilité elle-même
      availabilities_to_create << build_availability(
        start_date, end_date, false
      )

      # Partie après l'indisponibilité
      if availability.end_date > end_date
        availabilities_to_create << build_availability(
          end_date, availability.end_date, true
        )
      end

      # Supprimer l'ancienne disponibilité et créer les nouvelles
      availability.destroy!

      availabilities_to_create.each do |new_availability|
        new_availability.skip_validation = true
        new_availability.save!
      end

      availabilities_to_create
    end
  end

  def merge_adjacent_availabilities(start_date, end_date)
    ActiveRecord::Base.transaction do
      # Trouver les disponibilités adjacentes
      before_availability = find_availability_ending_at(start_date)
      after_availability = find_availability_starting_at(end_date)
      current_unavailability = find_unavailability_in_range(start_date, end_date)

      if before_availability && after_availability
        # Fusionner les trois parties
        before_availability.update!(end_date: after_availability.end_date, skip_validation: true)
        after_availability.destroy!
        current_unavailability&.destroy!
      elsif before_availability
        # Étendre la disponibilité précédente
        before_availability.update!(end_date: end_date, skip_validation: true)
        current_unavailability&.destroy!
      elsif after_availability
        # Étendre la disponibilité suivante
        after_availability.update!(start_date: start_date, skip_validation: true)
        current_unavailability&.destroy!
      else
        # Créer une nouvelle disponibilité
        new_availability = build_availability(start_date, end_date, true)
        new_availability.skip_validation = true
        new_availability.save!
        current_unavailability&.destroy!
      end
    end
  end

  def find_availability_ending_at(date)
    @user.availabilities.find_by(end_date: date, available: true)
  end

  def find_availability_starting_at(date)
    @user.availabilities.find_by(start_date: date, available: true)
  end

  def find_unavailability_in_range(start_date, end_date)
    @user.availabilities.find_by(
      start_date: start_date,
      end_date: end_date,
      available: false
    )
  end

  def build_availability(start_date, end_date, available)
    Availability.new(
      user: @user,
      start_date: start_date,
      end_date: end_date,
      available: available
    )
  end
end
