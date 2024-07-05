class Appointment < ApplicationRecord
  after_save :create_availability
  belongs_to :user

  validates :start_date, presence: true, comparison: { greater_than: Date.today }
  validates :end_date, comparison: { greater_than: :start_date },
                       presence: true
  validates :user_id, presence: true
  validates :comment, presence: true, length: { maximum: 500 }

  enum status: {
    hold: 0,
    accepted: 1,
    finished: 2,
    canceled: 3
  }

  def start_time
    self.start_date
  end

  def end_time
    self.end_date
  end

  private

  def create_availability
    Availability.create!(start_date: self.start_date, end_date: self.end_date, available: false) if self.status != "hold"
  end
end
