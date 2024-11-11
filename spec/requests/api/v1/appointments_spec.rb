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

  describe "GET /show" do
    it "get one appointment informations for customer" do
      save_appointments
      get api_v1_appointment_path(validAppointmentUser1), headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(serialized_response["message"]).to include("Appointment found.")
      expect(serialized_response["data"]["appointment"]["customer_id"].to_i).to eq customer.id
    end

    it "get one appointment informations for seller" do
      save_appointments
      get api_v1_appointment_path(validAppointmentUser1), headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(serialized_response["message"]).to include("Appointment found.")
      expect(serialized_response["data"]["appointment"]["seller_id"].to_i).to eq user.id
    end

    it "can't get appointment from other user" do
      save_appointments
      get api_v1_appointment_path(validAppointmentUser1), headers: user2_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unauthorized)
      expect(serialized_response["message"]).to include("You need to be the seller, the customer, or an admin to perform this action.")
    end
  end

  describe "CREATE /create" do
    it "customer can create appointment with auto-calculated end_date" do
      post api_v1_appointments_path, params: { appointment: { start_date: Time.now + 5.minutes, comment: "Hello world" }, appointment_services: [serviceUser1.id] }, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(user.appointments.count).to eq 1
      expect(customer.appointments.count).to eq 1
      expect(I18n.l(serialized_response["data"]["end_date"].to_datetime, format: :custom)).to eq I18n.l(Time.now + 5.minutes + serviceUser1.time.minutes, format: :custom)
    end

    it "appointment have a auto calculated price" do
      post api_v1_appointments_path, params: { appointment: { start_date: Time.now + 5.minutes, comment: "Hello world" }, appointment_services: [serviceUser1.id] }, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"]["price"]).to eq serviceUser1.price
    end

    it "customer can't create appointment if start_date or end_date is not in availabilities range" do
      post api_v1_appointments_path, params: { appointment: { start_date: Time.now + 3.hours, comment: "Hello world" }, appointment_services: [serviceUser1.id] }, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["message"]).to include("Can't create appointment:")
      expect(serialized_response["errors"]).to include("Availability Start_date and End_date necessary included in an availability range.")
      expect(customer.appointments.count).to eq 0
    end

    it "customer can't create appointment if appointment_services = nil && seller_id = nil" do
      post api_v1_appointments_path, params: { appointment: { start_date: Time.now, end_date: Time.now + 5.minutes, comment: "Hello world" } }, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["message"]).to include("Seller_id required!")
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "customer can't create appointment if appointment_services || end_date = nil" do
      post api_v1_appointments_path, params: { appointment: { start_date: Time.now, comment: "Hello world" } }, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["message"]).to include("Appointment_services OR End_date required!")
    end
  end

  describe "UPDATE /update" do
    it "Customer can update appointment's date if status is hold" do
      save_appointments
      patch api_v1_appointment_path(validAppointmentUser1), params: { appointment: { start_date: Time.now + 10.minutes, end_date: Time.now + 15.minutes } }, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(I18n.l(serialized_response["data"]["start_date"].to_datetime, format: :custom)).to eq I18n.l(Time.now + 10.minutes, format: :custom)
      expect(I18n.l(serialized_response["data"]["end_date"].to_datetime, format: :custom)).to eq I18n.l(Time.now + 15.minutes, format: :custom)
    end

    it "Customer can't update appointment's date if isn't hold" do
      validAppointmentUser1.status = "accepted"
      save_appointments
      patch api_v1_appointment_path(validAppointmentUser1), params: { appointment: { start_date: Time.now + 10.minutes, end_date: Time.now + 15.minutes } }, headers: customer_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:forbidden)
    end

    it "Seller can update appointment" do
      save_appointments
      patch api_v1_appointment_path(validAppointmentUser1), params: { appointment: { status: "accepted", seller_comment: "Hello world" } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
    end

    it "If a appointment is accepted, availabilities are sliced" do
      expect(user.availabilities.count).to eq 2
      save_appointments
      patch api_v1_appointment_path(validAppointmentUser1), params: { appointment: { status: "accepted", seller_comment: "Hello world" } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(user.availabilities.count).to eq 4
    end

    it "other user can't update appointment" do
      save_appointments
      patch api_v1_appointment_path(validAppointmentUser1), params: { appointment: { status: "accepted", seller_comment: "Hello world" } }, headers: user2_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:forbidden)
      expect(serialized_response["message"]).to include("You can't modify this appointment, because you're not the creator or the status is not hold or you want modifying date after accepted status.")
    end
  end
end
