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

  def self.set_unavailability(start_date, end_date, user, availability = nil, overlapping_availabilities = nil)
    if overlapping_availabilities
      overlapping_availabilities.each do |overlapped_availability|
        if availability.start_date < overlapped_availability.start_date && availability.end_date < overlapped_availability.end_date
          availability.end_date = overlapped_availability.start_date

        elsif availability.start_date < overlapped_availability.end_date && availability.start_date > overlapped_availability.start_date && availability.end_date > overlapped_availability.end_date
          availability.start_date = overlapped_availability.end_date
          
        elsif availability.start_date < overlapped_availability.start_date && availability.end_date > overlapped_availability.end_date
          new_end_availability = Availability.new(
            start_date: overlapped_availability.end_date,
            end_date: availability.end_date,
            available: availability.available,
            user: availability.user
          )
          availability.end_date = overlapped_availability.start_date
        end
        update_availabilities(new_end_availability, availability, overlapped_availability)
      end
    else
      current_availability = find_current_availability(start_date, end_date, user)
      return if current_availability.nil?

      new_end_availability = create_new_end_availability(end_date, current_availability)
      new_unavailability = create_new_unavailability(start_date, end_date, current_availability, user)
      current_availability.end_date = start_date
      update_availabilities(new_end_availability, new_unavailability, current_availability)
    end
  end

  private



  def no_overlapping_dates
    return if skip_validation || destroyed?

    overlapping_availabilities = Availability
                               .where(user_id:)
                               .where.not(id:)
                               .where('start_date < ? AND end_date > ?', end_date, start_date)
                               .where(available: !available)
                               .order(:start_date)

    Availability.set_unavailability(start_date, end_date, user, self, overlapping_availabilities) if overlapping_availabilities.exists?
  end

  def no_overlapping_dates_same_status
    return if skip_validation || destroyed?

    overlapping_availabilities = Availability
                               .where(user_id:)
                               .where.not(id:)
                               .where(available:)
                               .where('start_date < ? AND end_date > ?', end_date, start_date)
                               .order(:start_date)
    return if overlapping_availabilities.blank?

    if overlapping_availabilities.count == 1
      self.start_date = overlapping_availabilities.first.start_date if overlapping_availabilities.first.start_date < self.start_date
      self.end_date = overlapping_availabilities.first.end_date if overlapping_availabilities.first.end_date > self.end_date
      overlapping_availabilities.destroy_all
      self.save
    else
      if overlapping_availabilities.where(available: !available).exists?
        errors.add(:overlapping_availabilities, "An Availability found with #{!available} status.")
        raise ActiveRecord::RecordInvalid.new(self)
      end
      self.start_date = overlapping_availabilities.first.start_date if overlapping_availabilities.first.start_date < self.start_date
      self.end_date = overlapping_availabilities.last.end_date if overlapping_availabilities.last.end_date > self.end_date
      overlapping_availabilities.destroy_all
      self.save
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
        user: current_availability.user
      )
      new_end_availability
    end

    def create_new_unavailability(start_date, end_date, current_availability, user)
      new_unavailability = Availability.new(
        start_date:,
        end_date:,
        available: !current_availability.available,
        user: current_availability.user
      )
      new_unavailability
    end

    def update_availabilities(new_end_availability, new_unavailability, current_availability)
      ActiveRecord::Base.transaction do
        current_availability.skip_validation = true if current_availability
        new_end_availability.skip_validation = true if new_end_availability
        new_unavailability.skip_validation = true if new_unavailability
        current_availability.save! if current_availability
        new_end_availability.save! if new_end_availability
        new_unavailability.save! if new_unavailability
      end
    end
  end
end
