# frozen_string_literal: true

class PriceUpdaterService
  def initialize(service)
    @service = service
  end

  def update_appointments
    return if @service.appointments.empty?

    @service.appointments.find_each(&:update_price)
  end
end
