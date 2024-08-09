# frozen_string_literal: true

class Availability < ApplicationRecord
  belongs_to :user
  before_create :set_unavailable, unless: :skip_before_create

  validates :available, inclusion: [true, false]
  validates :start_date, presence: true
  validates :end_date, comparison: { greater_than: :start_date }, presence: true
  validate :no_overlapping_dates

  attr_accessor :skip_before_create

  private

  def set_unavailable
    current_availability = Availability.where('start_date <= ? AND end_date >= ? AND available = ?', start_date,
                                              end_date, true)
    return if current_availability.empty? || available

    current_availability.each do |cur|
      new_availability = Availability.new(start_date: end_date, end_date: cur.end_date, available: true,
                                          user_id: cur.user_id)
      new_availability.skip_before_create = true
      new_availability.save!
      cur.update(end_date: start_date)
    end
  end

  def no_overlapping_dates
    overlapping_availability = Availability
                               .where(user_id:)
                               .where.not(id:)
                               .where('start_date < ? AND end_date > ?', end_date, start_date)

    errors.add(:base, 'Les dates se chevauchent avec une disponibilité existante.') if overlapping_availability.exists?
  end
end
