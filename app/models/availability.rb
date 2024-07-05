class Availability < ApplicationRecord
  before_create :set_unavailable
  validates :available, inclusion: [true, false]
  validates :start_date, presence: true
  validates :end_date, comparison: { greater_than: :start_date },
                       presence: true

  def start_time
    self.start_date
  end

  def end_time
    self.end_date
  end

  def self.availabilities
    self.where(available: true).map do |availability|
      {from: availability.start_date, to: availability.end_date}
    end
  end

  private

  def set_unavailable
    current_availability = Availability.where(["start_date <= ? and end_date >= ? and available = ?", self.start_date, self.end_date, true])
    puts current_availability.size
    if current_availability.size > 0
      current_availability.each do |cur|
        Availability.create(start_date: self.end_date, end_date: cur.end_date, available: true)
        cur.update(end_date: self.start_date)
      end
    end
  end
end
