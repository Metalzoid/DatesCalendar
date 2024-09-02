# frozen_string_literal: true

class Appointment < ApplicationRecord
  after_save :create_availability, if: :saved_change_to_status?
  after_save :restore_availabilities, if: :saved_change_to_status?

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

  enum status: { hold: 0, accepted: 1, finished: 2, canceled: 3 }

  def self.by_admin(admin)
    joins(:customer, :seller).merge(User.by_admin(admin))
  end

  private

  def transform_date(date)
    I18n.l(date, format: :custom)
  end

  def check_availability
    availabilities = Availability.by_admin(seller.admin).where(available: true, user: seller)
    overlapping_availability = availabilities.any? do |availability|
      start_date >= availability.start_date && end_date <= availability.end_date
    end
    return if overlapping_availability

    errors.add(:availability, 'Start_date and End_date necessary included in an availability range.')
  end

  def create_availability
    return unless [saved_change_to_status&.last || status].include?('accepted')

    @availability = Availability.set_unavailability(start_date, end_date, seller)
  end

  def restore_availabilities
    return unless [status, saved_change_to_status&.last].include?('canceled') && saved_change_to_status&.first == 'accepted'

    @before = Availability.find_by('start_date < ? AND end_date = ? AND user_id = ?', (saved_change_to_start_date&.first || start_date),
                                   (saved_change_to_start_date&.first || start_date), seller.id)
    @availability = Availability.find_by(start_date: saved_change_to_start_date&.first || start_date,
                                         end_date: saved_change_to_end_date&.first || end_date,
                                         user: seller)
    @after = Availability.find_by('start_date = ? AND end_date > ? AND user_id = ?', (saved_change_to_end_date&.first || end_date),
                                  (saved_change_to_end_date&.first || end_date), seller.id)

    ActiveRecord::Base.transaction do
      @after.update!(start_date: @before.start_date, skip_validation: true)
      @availability.destroy!
      @before.destroy!
    end
  end
end
