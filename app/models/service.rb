class Service < ApplicationRecord
  belongs_to :user
  has_many :appointment_services, dependent: :destroy

  after_update :update_all_appointments
  after_commit :update_price

  validates :title, presence: true
  validates :price, presence: true, numericality: { only_float: true }

  private

  def update_price
    Appointment.all.each { |appointment| appointment.update_price }
  end

  def update_all_appointments
    appointment_ids = appointment_services.pluck(:appointment_id).uniq
    appointments = Appointment.where(id: appointment_ids)

    appointments.find_each do |appointment|
      appointment.calculate_total_price
    end
  end
end
