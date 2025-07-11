# frozen_string_literal: true

# Service pour gérer les chevauchements de disponibilités
class AvailabilityOverlapService
  def initialize(availability, overlapping_availabilities = nil)
    @availability = availability
    @overlapping_availabilities = overlapping_availabilities || find_overlapping_availabilities
    @resulting_availabilities = []
  end

  def call
    return [@availability] if @overlapping_availabilities.empty?

    process_overlaps
    @resulting_availabilities
  end

  private

  def find_overlapping_availabilities
    Availability
      .where(user_id: @availability.user_id)
      .where.not(id: @availability.id)
      .where('start_date <= ? AND end_date >= ?', @availability.end_date, @availability.start_date)
      .order(start_date: :desc)
  end

  def process_overlaps
    @overlapping_availabilities.each do |overlapped_availability|
      if different_availability_types?(overlapped_availability)
        handle_different_types(overlapped_availability)
      else
        # Même type de disponibilité : on fusionne les availabilities
        merge_same_type_availabilities(overlapped_availability)
      end
    end

    @resulting_availabilities << @availability unless @availability.destroyed?
  end

  def different_availability_types?(overlapped_availability)
    overlapped_availability.available != @availability.available
  end

  def handle_different_types(overlapped_availability)
    case overlap_type(overlapped_availability)
    when :partial_start
      handle_partial_start_overlap(overlapped_availability)
    when :partial_end
      handle_partial_end_overlap(overlapped_availability)
    when :complete_inside
      handle_complete_inside_overlap(overlapped_availability)
    when :complete_outside
      handle_complete_outside_overlap(overlapped_availability)
    end
  end

  def overlap_type(overlapped_availability)
    if @availability.start_date < overlapped_availability.start_date &&
       @availability.end_date < overlapped_availability.end_date
      :partial_start
    elsif @availability.start_date > overlapped_availability.start_date &&
          @availability.start_date < overlapped_availability.end_date &&
          @availability.end_date > overlapped_availability.end_date
      :partial_end
    elsif @availability.start_date < overlapped_availability.start_date &&
          @availability.end_date > overlapped_availability.end_date
      :complete_inside
    else
      :complete_outside
    end
  end

  def handle_partial_start_overlap(overlapped_availability)
    @availability.end_date = overlapped_availability.start_date
  end

  def handle_partial_end_overlap(overlapped_availability)
    @availability.start_date = overlapped_availability.end_date
  end

  def handle_complete_inside_overlap(overlapped_availability)
    # La nouvelle disponibilité englobe complètement l'ancienne
    # On créé une nouvelle disponibilité après l'ancienne
    new_availability = Availability.new(
      start_date: overlapped_availability.end_date,
      end_date: @availability.end_date,
      available: @availability.available,
      user: @availability.user
    )

    @availability.end_date = overlapped_availability.start_date
    @resulting_availabilities << new_availability
  end

  def handle_complete_outside_overlap(overlapped_availability)
    # L'ancienne disponibilité englobe complètement la nouvelle indisponibilité
    # On divise l'ancienne en deux parties : avant et après l'indisponibilité

    # Partie après l'indisponibilité - créer une nouvelle availability avec le même type que l'originale
    new_end_part = Availability.new(
      start_date: @availability.end_date,
      end_date: overlapped_availability.end_date,
      available: overlapped_availability.available,
      user: overlapped_availability.user
    )

    # Modifier l'availability d'origine pour qu'elle se termine au début de l'indisponibilité
    overlapped_availability.end_date = @availability.start_date

    # Ajouter les availabilities modifiées et créées aux résultats
    @resulting_availabilities << overlapped_availability  # L'availability d'origine modifiée
    @resulting_availabilities << new_end_part            # La nouvelle partie après l'indisponibilité
  end

  def merge_same_type_availabilities(overlapped_availability)
    # Fusionner les availabilities du même type en étendant les dates
    # pour couvrir la plus grande plage possible

    # Calculer les nouvelles dates pour englober les deux availabilities
    new_start_date = [@availability.start_date, overlapped_availability.start_date].min
    new_end_date = [@availability.end_date, overlapped_availability.end_date].max

    # Mettre à jour la nouvelle availability avec la plage fusionnée
    @availability.start_date = new_start_date
    @availability.end_date = new_end_date

    # Supprimer l'ancienne availability car elle est maintenant fusionnée
    overlapped_availability.destroy
  end
end
