class Availability < ApplicationRecord
  belongs_to :user
  before_create :set_unavailable, unless: :skip_before_create

  validates :available, inclusion: [true, false]
  validates :start_date, presence: true
  validates :end_date, comparison: { greater_than: :start_date }, presence: true

  attr_accessor :skip_before_create

  private

  def set_unavailable
    current_availability = Availability.where('start_date <= ? AND end_date >= ? AND available = ?', start_date, end_date, true)
    return if current_availability.empty? || available

    current_availability.each do |cur|
      new_availability = Availability.new(start_date: end_date, end_date: cur.end_date, available: true, user_id: cur.user_id)
      new_availability.skip_before_create = true
      new_availability.save!
      cur.update(end_date: start_date)
    end
  end
end
