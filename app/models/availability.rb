# frozen_string_literal: true

class Availability < ApplicationRecord
  belongs_to :user

  validates :available, inclusion: { in: [true, false] }
  validates :start_date, presence: true
  validates :end_date, presence: true, comparison: { greater_than: :start_date }
  validate :no_overlapping_dates, unless: :skip_validation

  attr_accessor :skip_validation

  def self.by_admin(admin)
    joins(:user).merge(User.by_admin(admin))
  end

  def self.set_unavailability(start_date, end_date, user)
    current_availability = Availability.find_by(
      'start_date <= ? AND end_date >= ? AND available = ? AND user_id = ?',
      start_date, end_date, true, user.id
    )
    return if current_availability.nil?

    new_end_availability = Availability.new(
      start_date: end_date,
      end_date: current_availability.end_date,
      available: true,
      user_id: current_availability.user_id
    )
    new_end_availability.skip_validation = true

    new_unavailability = Availability.new(
      start_date: start_date,
      end_date: end_date,
      available: false,
      user_id: user.id
    )
    new_unavailability.skip_validation = true

    ActiveRecord::Base.transaction do
      new_end_availability.save!
      new_unavailability.save!
      current_availability.update!(end_date: start_date)
    end
  end

  private

  def no_overlapping_dates
    return if skip_validation || destroyed?

    overlapping_availability = Availability
                               .where(user_id: user_id)
                               .where.not(id: id)
                               .where('start_date < ? AND end_date > ?', end_date, start_date)

    if overlapping_availability.exists?
      errors.add(:base, 'Dates overlap with existing availability.')
    end
  end
end
