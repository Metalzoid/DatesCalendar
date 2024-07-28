class PriceUpdaterService
  def initialize(service)
    @service = service
  end

  def update_appointments
    @service.appointments.find_each do |appointment|
      appointment.update_price
    end
  end
end
