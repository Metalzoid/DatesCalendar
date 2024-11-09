require 'rails_helper'
require 'json'

RSpec.describe "Api::V1::Availabilities", type: :request do

  let!(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end
  let!(:user) { User.create(email: "user@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let!(:user2) { User.create(email: "user2@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let!(:serviceUser1) { Service.create(title: "service user 1", time: 50, price: 50, user: user) }
  let!(:serviceUser2) { Service.create(title: "service user 2", time: 50, price: 50, user: user2) }
  let!(:availabilityUser1) { Availability.new(start_date: I18n.l(Time.now, format: :custom), end_date: I18n.l(Time.now  + 2.hours, format: :custom), available: true, user: user) }
  let!(:unavailabilityUser1) { Availability.new(start_date: I18n.l(Time.now + 3.hours, format: :custom), end_date: I18n.l(Time.now + 4.hours, format: :custom), available: false, user: user) }
  let!(:availabilityUser2) { Availability.new(start_date: I18n.l(Time.now, format: :custom), end_date: I18n.l(Time.now + 2.hours, format: :custom), available: true, user: user2) }
  let!(:unavailabilityUser2) { Availability.new(start_date: I18n.l(Time.now + 3.hours, format: :custom), end_date: I18n.l(Time.now + 4.hours, format: :custom), available: false, user: user2) }

  before do
    post user_session_path, params: { user: { email: user.email, password: "azerty" } }
    @token = response.headers['Authorization'].split(' ').last
    @headers = { 'Authorization' => "Bearer #{@token}" }
  end

  def save_availabilities
    availabilityUser1.save!
    availabilityUser2.save!
    unavailabilityUser1.save!
    unavailabilityUser2.save!
  end


  describe "GET /index" do
    it 'get status 200' do
      save_availabilities
      get '/api/v1/availabilities', headers: @headers
      expect(response).to have_http_status(:ok)
    end

    it 'requires valid token' do
      get '/api/v1/availabilities'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'get status 404 when no availabilities founded' do
      get '/api/v1/availabilities', headers: @headers
      expect(response).to have_http_status(:not_found)
    end

    it 'get valid JSON' do
      save_availabilities
      get '/api/v1/availabilities', headers: @headers
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response).to include("message", "data")
    end

    it 'get 1 availability for current user' do
      save_availabilities
      get '/api/v1/availabilities', headers: @headers
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"]["availabilities"].count).to eq 1
    end

    it 'get 1 availability (from -> to) formated for current user' do
      save_availabilities
      get '/api/v1/availabilities', headers: @headers
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"]["dates"].count).to eq 1
    end

    it 'get 1 unavailability for current user' do
      save_availabilities
      get '/api/v1/availabilities', headers: @headers, params: {available: false}
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"]["availabilities"].count).to eq 1
    end

    it 'get 1 unavailability (from -> to) formated for current user' do
      save_availabilities
      get '/api/v1/availabilities', headers: @headers, params: {available: false}
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"]["dates"].count).to eq 1
    end

    it 'get formated by interval of minutes for current user' do
      save_availabilities
      get '/api/v1/availabilities', headers: @headers, params: {interval: 60}
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"]["dates"].count).to eq 2
    end

    it 'get availabilities for a other user (scoped by admin)' do
      save_availabilities
      get '/api/v1/availabilities', headers: @headers, params: {seller_id: user2.id}
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"]["availabilities"][0]["user_id"]).to eq user2.id
    end
  end

  describe "POST /create" do
    it "create a new availability" do
      post api_v1_availabilities_path, params: { availability: { start_date: Time.now + 5.hours, end_date: Time.now + 6.hours, available: true } }, headers: @headers
      expect(response).to have_http_status(:created)
      expect(user.availabilities.count).to eq 1
    end

    it "can't create without start_date" do
      post api_v1_availabilities_path, params: { availability: {  end_date: Time.now + 6.hours, available: true } }, headers: @headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["start_date"]).to include("can't be blank")
      expect(user.availabilities.count).to eq 0
    end

    it "can't create without end_date" do
      post api_v1_availabilities_path, params: { availability: {  start_date: Time.now + 6.hours, available: true } }, headers: @headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["end_date"]).to include("can't be blank")
      expect(user.availabilities.count).to eq 0
    end

    it "can't create without status available" do
      post api_v1_availabilities_path, params: { availability: { start_date: Time.now + 5.hours, end_date: Time.now + 6.hours } }, headers: @headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["available"]).to include("is not included in the list")
      expect(user.availabilities.count).to eq 0
    end
  end
end
