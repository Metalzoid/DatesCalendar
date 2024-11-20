# frozen_string_literal: true

# Availability Model
class Availability < ApplicationRecord
  belongs_to :user

  validates :available, inclusion: { in: [true, false] }
  validates :start_date, presence: true
  validates :end_date, presence: true, comparison: { greater_than: :start_date }
  validate :no_overlapping_dates, unless: :skip_validation
  validate :no_overlapping_dates_same_status, unless: :skip_validation
  after_commit :send_data_cable

  attr_accessor :skip_validation

  def self.by_admin(admin)
    joins(:user).merge(User.by_admin(admin))
  end

  def self.set_unavailability(start_date, end_date, user, availability = nil)
    current_availability = find_current_availability(start_date, end_date, user)
    return if current_availability.nil?

    new_end_availability = create_new_end_availability(end_date, current_availability)
    new_unavailability = availability || create_new_unavailability(start_date, end_date, current_availability.available, user)
    update_availabilities(new_end_availability, new_unavailability, current_availability, start_date)
  end

  private

  def no_overlapping_dates
    return if skip_validation || destroyed?

    overlapping_availability = Availability
                               .where(user_id:)
                               .where.not(id:)
                               .where('start_date < ? AND end_date > ?', end_date, start_date)
                               .where(available: !available)
                               .order(:start_date)
    Availability.set_unavailability(start_date, end_date, user, self) if overlapping_availability.any?
  end

  def no_overlapping_dates_same_status
    return if skip_validation || destroyed?

    overlapping_availability = Availability
                               .where(user_id:)
                               .where.not(id:)
                               .where(available:)
                               .where('start_date < ? AND end_date > ?', end_date, start_date)
                               .order(:start_date)
    return if overlapping_availability.blank?

    if overlapping_availability.count == 1
      self.start_date = overlapping_availability.first.start_date if overlapping_availability.first.start_date < self.start_date
      self.end_date = overlapping_availability.first.end_date if overlapping_availability.first.end_date > self.end_date
      self.skip_validation
      overlapping_availability.destroy_all
      self.save
    else
      self.start_date = overlapping_availability.first.start_date if overlapping_availability.first.start_date < self.start_date
      self.end_date = overlapping_availability.last.end_date if overlapping_availability.last.end_date > self.end_date
      overlapping_availability.destroy_all
    end
  end

  class << self
    private

    def find_current_availability(start_date, end_date, user)
      Availability.find_by(
        'start_date <= ? AND end_date >= ? AND user_id = ?',
        start_date, end_date, user.id
      )
    end

    def create_new_end_availability(end_date, current_availability)
      new_end_availability = Availability.new(
        start_date: end_date,
        end_date: current_availability.end_date,
        available: current_availability.available,
        user_id: current_availability.user_id
      )
      new_end_availability.skip_validation = true
      new_end_availability
    end

    def create_new_unavailability(start_date, end_date, available, user)
      new_unavailability = Availability.new(
        start_date:,
        end_date:,
        available: !available,
        user_id: user.id
      )
      new_unavailability.skip_validation = true
      new_unavailability
    end

    def update_availabilities(new_end_availability, new_unavailability, current_availability, start_date)
      ActiveRecord::Base.transaction do
        current_availability.end_date = start_date
        current_availability.skip_validation = true
        current_availability.save!
        new_end_availability.save!
        new_unavailability.save!
      end
    end
  end
end
