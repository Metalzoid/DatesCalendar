# frozen_string_literal: true

# Availability Model
class Availability < ApplicationRecord
  belongs_to :user

  validates :available, inclusion: { in: [true, false] }
  validates :start_date, presence: true
  validates :end_date, presence: true, comparison: { greater_than: :start_date }
  validate :no_overlapping_dates, unless: :skip_validation

  attr_accessor :skip_validation

  scope :by_admin, ->(admin) { joins(:user).merge(User.by_admin(admin)) }
  scope :available_slots, -> { where(available: true) }
  scope :unavailable_slots, -> { where(available: false) }

  # Méthode simplifiée pour créer une indisponibilité
  # Délègue maintenant au service principal
  def self.create_unavailability_for_user(start_date, end_date, user)
    service = AvailabilityManagementService.new(user)
    service.create_unavailability_for_appointment(start_date, end_date)
  end

  # Méthode simplifiée pour restaurer une disponibilité
  def self.restore_availability_for_user(start_date, end_date, user)
    service = AvailabilityManagementService.new(user)
    service.restore_availability_after_appointment_cancellation(start_date, end_date)
  end

  private

  def no_overlapping_dates
    return if skip_validation || destroyed?

    # Ne traiter les chevauchements que si les validations de base sont valides
    return unless valid_for_overlap_processing?

    # Trouver les chevauchements directement
    overlapping_availabilities = find_overlapping_availabilities
    return unless overlapping_availabilities.exists?

    # Utiliser directement le service de chevauchement sans rappeler la validation
    overlap_service = AvailabilityOverlapService.new(self, overlapping_availabilities)
    resulting_availabilities = overlap_service.call

    # Traiter les résultats en évitant la récursion
    ActiveRecord::Base.transaction do
      # Marquer tous les objets pour éviter la validation récursive
      resulting_availabilities.each do |av|
        av.skip_validation = true
      end

      # Sauvegarder les nouvelles disponibilités créées
      resulting_availabilities.reject { |av| av == self }.each(&:save!)

      # Si self (l'availability d'origine) a été modifiée par le service et est dans les résultats,
      # on doit aussi la sauvegarder, mais la validation normale du modèle la sauvegarde déjà
    end
  end

  def valid_for_overlap_processing?
    # Vérifier que les champs de base sont présents et valides
    start_date.present? &&
      end_date.present? &&
      !available.nil? &&
      user.present? &&
      start_date < end_date
  end

  def find_overlapping_availabilities
    Availability
      .where(user_id: user_id)
      .where.not(id: id)
      .where('start_date < ? AND end_date > ?', end_date, start_date)
      .order(start_date: :desc)
  end
end
