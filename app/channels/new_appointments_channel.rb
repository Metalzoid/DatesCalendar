class NewAppointmentsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "new_appointments_#{current_user.id}"
    NewAppointmentsChannel.send_appointments(current_user)
  end

  def unsubscribed
    stop_all_streams
  end

  def self.send_appointments(user)
    appointments = user.appointments
    .select { |appointment| appointment.status == "hold" && appointment.start_date > Time.now }
    .map { |appointment| AppointmentSerializer.new(appointment).serializable_hash.dig(:data, :attributes)}

    data = {
      appointments: appointments,
    }

    ActionCable.server.broadcast("new_appointments_#{user.id}", data)
  end
end
