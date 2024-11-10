require 'rails_helper'
require 'json'

RSpec.describe "Api::V1::Services", type: :request do
  let!(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end
  let!(:user) { User.create(email: "user@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let!(:user2) { User.create(email: "user2@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let!(:serviceUser1) { Service.new(title: "service user 1", time: 50, price: 50, user: user) }
  let!(:serviceUser2) { Service.new(title: "service user 2", time: 50, price: 50, user: user2) }

  def save_services
    serviceUser1.save!
    serviceUser2.save!
  end

  let(:user_headers) do
    post user_session_path, params: { user: { email: user.email, password: user.password } }
    token = response.headers['Authorization'].split(' ').last
    { 'Authorization' => "Bearer #{token}" }
  end

  describe "GET /index" do
    it 'get status 200' do
      save_services
      get '/api/v1/services', headers: user_headers
      expect(response).to have_http_status(:ok)
    end

    it 'requires valid token' do
      get '/api/v1/services'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'get status 404 when no services founded' do
      get '/api/v1/services', headers: user_headers
      expect(response).to have_http_status(:not_found)
    end

    it 'get valid JSON' do
      save_services
      get '/api/v1/services', headers: user_headers
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response).to include("message", "data")
    end

    it 'get 1 services JSON for current user' do
      save_services
      get '/api/v1/services', headers: user_headers, params: {seller_id: user.id}
      expect(response).to have_http_status(:ok)
      serialized_response = JSON.parse(response.body)
      expect(serialized_response["data"].count).to eq 1
    end
  end

  describe "POST /create" do
    it "create a new service" do
      post api_v1_services_path, params: { service: { title:"Create a new Service", time: 5, price: 5 } }, headers: user_headers
      expect(response).to have_http_status(:created)
      expect(user.services.count).to eq 1
    end

    it "can't create without title" do
      post api_v1_services_path, params: { service: { time: 5, price: 5 } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["title"]).to include("can't be blank")
      expect(user.services.count).to eq 0
    end

    it "can't create without time" do
      post api_v1_services_path, params: { service: { title: "Create a new Service", price: 5 } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["time"]).to include("can't be blank")
      expect(user.services.count).to eq 0
    end

    it "can't create without price" do
      post api_v1_services_path, params: { service: { title: "Create a new Service", time: 5 } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["price"]).to include("can't be blank")
      expect(user.services.count).to eq 0
    end
  end

  describe "UPDATE /update" do
    it "update a service" do
      save_services
      patch api_v1_service_path(serviceUser1), params: { service: { title: "Update a new Service", time: 5, price: 5 } }, headers: user_headers
      expect(response).to have_http_status(:ok)
      expect(user.services.count).to eq 1
      expect(user.services.last.title).to include("Update a new Service")
    end

    it "can't update without title" do
      save_services
      patch api_v1_service_path(serviceUser1), params: { service: { title: nil, time: 5, price: 5 } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["title"]).to include("can't be blank")
    end

    it "can't update without time" do
      save_services
      patch api_v1_service_path(serviceUser1), params: { service: { time: nil, price: 5 } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["time"]).to include("can't be blank")
    end

    it "can't update without price" do
      save_services
      patch api_v1_service_path(serviceUser1), params: { service: { price: nil } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(serialized_response["errors"]["price"]).to include("can't be blank")
    end

    it "Can't update another user's service" do
      save_services
      patch api_v1_service_path(serviceUser2), params: { service: { title: "Update Service from other user" } }, headers: user_headers
      serialized_response = JSON.parse(response.body)
      expect(response).to have_http_status(:forbidden)
      expect(serialized_response["message"]).to include("Can't update another user's service.")
    end
  end
end
