require 'rails_helper'

RSpec.describe "Api::V1::Appointments", type: :request do
  let!(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end
  let!(:user) { User.create(email: "user@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let!(:user2) { User.create(email: "user2@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let!(:customer) { User.create(email: "customer@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "customer", admin: admin)}
  let!(:serviceUser1) { Service.create(title: "service user 1", time: 5, price: 50, user: user) }
  let!(:serviceUser2) { Service.create(title: "service user 2", time: 5, price: 50, user: user2) }
  let!(:availabilityUser1) { Availability.create(start_date: I18n.l(Time.now, format: :custom), end_date: I18n.l(Time.now  + 2.hours, format: :custom), available: true, user: user) }
  let!(:unavailabilityUser1) { Availability.create(start_date: I18n.l(Time.now + 3.hours, format: :custom), end_date: I18n.l(Time.now + 4.hours, format: :custom), available: false, user: user) }
  let!(:availabilityUser2) { Availability.create(start_date: I18n.l(Time.now, format: :custom), end_date: I18n.l(Time.now + 2.hours, format: :custom), available: true, user: user2) }
  let!(:unavailabilityUser2) { Availability.create(start_date: I18n.l(Time.now + 3.hours, format: :custom), end_date: I18n.l(Time.now + 4.hours, format: :custom), available: false, user: user2) }
  let!(:validAppointmentUser1) { Appointment.new(start_date: Time.now + 5.minutes, end_date: Time.now + 10.minutes, comment: "Hello world !", seller: user, customer: customer) }

  let(:user_headers) do
    post user_session_path, params: { user: { email: user.email, password: user.password } }
    token = response.headers['Authorization'].split(' ').last
    { 'Authorization' => "Bearer #{token}" }
  end

  let(:user2_headers) do
    post user_session_path, params: { user: { email: user2.email, password: user2.password } }
    token = response.headers['Authorization'].split(' ').last
    { 'Authorization' => "Bearer #{token}" }
  end

  let(:customer_headers) do
    post user_session_path, params: { user: { email: customer.email, password: customer.password } }
    token = response.headers['Authorization'].split(' ').last
    { 'Authorization' => "Bearer #{token}" }
  end

  def save_appointments
    validAppointmentUser1.save!
  end

  describe "GET /index" do
    it "get 0 appointments" do
      get api_v1_appointments_path, headers: user_headers
      expect(response).to have_http_status(:not_found)
    end

    it "get 1 appointment for seller" do
      save_appointments
      get api_v1_appointments_path, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(serialized_response["data"].count).to eq 1
    end

    it "get 1 appointment for customer" do
      save_appointments
      get api_v1_appointments_path, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(serialized_response["data"].count).to eq 1
    end

    it "get 0 appointment for other user" do
      save_appointments
      get api_v1_appointments_path, headers: user2_headers
      expect(response).to have_http_status(:not_found)
    end

    it "get unauthorized if not connected" do
      get api_v1_appointments_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "CREATE /create" do
    it "customer can create appointment with auto-calculated end_date" do
      post api_v1_appointments_path, params: { appointment: { start_date: Time.now + 5.minutes, comment: "Hello world" }, appointment_services: [serviceUser1.id]}, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(user.appointments.count).to eq 1
      expect(customer.appointments.count).to eq 1
      expect(I18n.l(serialized_response["data"]["end_date"].to_datetime, format: :custom)).to eq I18n.l(Time.now + 5.minutes + serviceUser1.time.minutes, format: :custom)
    end

    it "appointment have a auto calculated price" do
      post api_v1_appointments_path, params: { appointment: { start_date: Time.now + 5.minutes, comment: "Hello world" }, appointment_services: [serviceUser1.id]}, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"]["price"]).to eq serviceUser1.price
    end

    it "customer can't create appointment if start_date or end_date is not in availabilities range" do
      post api_v1_appointments_path, params: { appointment: { start_date: Time.now + 3.hours, comment: "Hello world" }, appointment_services: [serviceUser1.id]}, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["message"]).to include("Can't create appointment:")
      expect(serialized_response["errors"]).to include("Availability Start_date and End_date necessary included in an availability range.")
      expect(customer.appointments.count).to eq 0
    end
  end
end
