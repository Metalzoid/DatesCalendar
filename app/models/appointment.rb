# frozen_string_literal: true

class Appointment < ApplicationRecord
  after_commit :after_commit_actions, unless: :skip_after_commit_actions?

  belongs_to :customer, class_name: 'User'
  belongs_to :seller, class_name: 'User'
  has_many :appointment_services, dependent: :destroy
  has_many :services, through: :appointment_services

  validates :start_date, presence: true, comparison: { greater_than: Time.now }
  validates :end_date, comparison: { greater_than: :start_date }, presence: true
  validates :comment, presence: true, length: { maximum: 500 }
  validates :customer_id, presence: true
  validates :seller_id, presence: true
  validate :check_availability

  enum status: { hold: 0, accepted: 1, finished: 2, canceled: 3 }

  def update_price
    new_price = services.sum(&:price)
    update(price: new_price)
  end

  private

  def after_commit_actions
    return if destroyed?

    ActiveRecord::Base.transaction do
      create_availability if status == 'accepted'
      update(status: 0) if status.nil?
    end
  end

  def skip_after_commit_actions?
    saved_change_to_price? || destroyed?
  end

  def transform_date(date)
    I18n.l(date, format: :custom)
  end

  def check_availability
    return unless status == 'hold' || status.nil?

    availabilities = Availability.where(available: true)
    overlapping_availability = availabilities.any? do |availability|
      start_date >= availability.start_date && end_date <= availability.end_date
    end
    return if overlapping_availability

    errors.add(:availability,
               'Les dates de début et de fin doivent être incluses dans une plage de disponibilité valide.')
  end

  def create_availability
    return unless status == 'accepted'

    Availability.create!(start_date:, end_date:, available: false,
                         user: seller)
  end
end
