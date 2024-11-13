class AllDatasChannel < ApplicationCable::Channel
  def subscribed
    stream_from "all_datas_user#{current_user.id}"
    AllDatasChannel.send_all_datas(current_user)
  end

  def unsubscribed
    stop_all_streams
  end

  def self.send_all_datas(current_user)
    appointments = current_user.appointments.map { |appointment| AppointmentSerializer.new(appointment).serializable_hash[:data][:attributes] }
    availabilities = current_user.availabilities.map { |availability| AvailabilitySerializer.new(availability).serializable_hash[:data][:attributes] }
    services = current_user.services.map { |service| ServiceSerializer.new(service).serializable_hash[:data][:attributes] }
    customers = current_user.appointments.map(&:customer).uniq(&:id).map { |customer| UserSerializer.new(customer).serializable_hash[:data][:attributes] }
    sellers = current_user.appointments.map(&:seller).uniq(&:id).map { |seller| UserSerializer.new(seller).serializable_hash[:data][:attributes] }

    data = {
      user: UserSerializer.new(current_user).serializable_hash[:data][:attributes],
      appointments: appointments,
      availabilities: availabilities,
      services: services
    }

    data[:customers] = customers if customers.present?
    data[:sellers] = sellers if sellers.present?

    ActionCable.server.broadcast("all_datas_user#{current_user.id}", data)
  end
end
