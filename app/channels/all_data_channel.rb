class AllDataChannel < ApplicationCable::Channel
  def subscribed
    stream_from "all_data_user#{current_user.id}"
    AllDataChannel.send_all_datas(current_user)
  end

  def unsubscribed
    stop_all_streams
  end

  def self.send_all_datas(current_user)
    appointments = current_user.appointments.map do |appointment|
      AppointmentSerializer.new(appointment).serializable_hash[:data][:attributes]
    end
    availabilities = current_user.availabilities.map do |availability|
      AvailabilitySerializer.new(availability).serializable_hash[:data][:attributes]
    end
    services = current_user.services.map do |service|
      ServiceSerializer.new(service).serializable_hash[:data][:attributes]
    end
    data = {
      user: UserSerializer.new(current_user).serializable_hash[:data][:attributes],
      appointments:,
      availabilities:,
      services:
  }
    ActionCable.server.broadcast("all_data_user#{current_user.id}", data)
  end
end
