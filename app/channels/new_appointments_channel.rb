class NewAppointmentsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "new_appointments_#{current_user.id}"
    AllDatasChannel.send_appointments
  end

  def unsubscribed
    stop_all_streams
  end

  def self.send_appointments
    appointments = current_user.appointments
    .select { |appointment| appointment.status == "hold" && appointment.start_date > Time.now }
    .map { |appointment| AppointmentSerializer.new(appointment).serialzable_hash.dig(:data, :attributes)}

    data = {
      appointments: appointments,
    }

    ActionCable.server.broadcast("new_appointments_#{current_user.id}", data)
  end
end
