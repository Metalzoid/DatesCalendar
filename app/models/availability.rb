# frozen_string_literal: true

# Availability Model
class Availability < ApplicationRecord
  belongs_to :user

  validates :available, inclusion: { in: [true, false] }
  validates :start_date, presence: true
  validates :end_date, presence: true, comparison: { greater_than: :start_date }
  validate :no_overlapping_dates, unless: :skip_validation
  after_commit :send_data_cable

  attr_accessor :skip_validation

  def self.by_admin(admin)
    joins(:user).merge(User.by_admin(admin))
  end

  def self.set_unavailability(start_date, end_date, user, availability = nil, overlapping_availabilities = nil)
    temp_availabilities = []
    if overlapping_availabilities
      overlapping_availabilities.each do |overlapped_availability|
        if overlapped_availability.available != availability.available
          if availability.start_date < overlapped_availability.start_date && availability.end_date < overlapped_availability.end_date
            availability.end_date = overlapped_availability.start_date
          elsif availability.start_date < overlapped_availability.end_date && availability.start_date > overlapped_availability.start_date && availability.end_date > overlapped_availability.end_date
            availability.start_date = overlapped_availability.end_date
          elsif availability.start_date < overlapped_availability.start_date && availability.end_date > overlapped_availability.end_date
            temp_availabilities << Availability.new(
              start_date: overlapped_availability.end_date,
              end_date: availability.end_date,
              available: availability.available,
              user: availability.user
            )
          end
          availability.end_date = overlapped_availability.start_date
          temp_availabilities << availability
          update_availabilities(params = temp_availabilities)
        else
          overlapped_availability.destroy
        end
      end
    else
      current_availability = find_current_availability(start_date, end_date, user)
      return if current_availability.nil?

      new_end_availability = create_new_end_availability(end_date, current_availability)
      new_unavailability = create_new_unavailability(start_date, end_date, current_availability, user)
      current_availability.end_date = start_date
      update_availabilities(params = [new_end_availability, new_unavailability, current_availability])
    end
  end

  private

  def no_overlapping_dates
    return if skip_validation || destroyed?

    overlapping_availabilities = Availability
                               .where(user_id:)
                               .where.not(id:)
                               .where('start_date < ? AND end_date > ?', end_date, start_date)
                               .order(start_date: :desc)

    Availability.set_unavailability(start_date, end_date, user, self, overlapping_availabilities) if overlapping_availabilities.exists?
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

    def update_availabilities(params = [])
      ActiveRecord::Base.transaction do
        params.each do |availability|
          availability.skip_validation = true
          availability.save
        end
      end

    end
  end
end
