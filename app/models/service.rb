class Service < ApplicationRecord
  belongs_to :user
  has_many :appointment_services, dependent: :destroy
  has_many :appointments, through: :appointment_services

  after_save :update_related_appointments

  validates :title, presence: true
  validates :price, presence: true, numericality: { only_float: true }
  validates :time, presence: true

  private

  def update_related_appointments
    PriceUpdaterService.new(self).update_appointments
  end
end
