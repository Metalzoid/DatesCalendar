# frozen_string_literal: true

class Service < ApplicationRecord
  belongs_to :user
  has_many :appointment_services, dependent: :destroy
  has_many :appointments, through: :appointment_services
  has_one :admin, through: :user

  after_save :update_related_appointments

  validates :title, presence: true
  validates :price, presence: true, numericality: { only_float: true }
  validates :time, presence: true

  def self.by_admin(admin)
    joins(:user).merge(User.by_admin(admin))
  end

  private

  def update_related_appointments
    appointments.find_each(&:update_price)
  end
end
