require 'rails_helper'

RSpec.describe Appointment, type: :model do
  let!(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end
  let!(:seller) { User.create(email: "seller@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "seller", admin: admin) }
  let!(:customer) { User.create(email: "customer@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "customer", admin: admin) }
  let!(:service) { Service.create!(title: "service", price: 15, time: 30, user: seller) }
  let!(:availability) { Availability.create!(start_date: Time.now, end_date: Time.now + 5.days, available: true, user: seller)}
  let!(:appointment1) { Appointment.create!(start_date: Time.now + 5.minutes, end_date: Time.now + 5.minutes + service.time.minutes, seller: seller, customer: customer, comment: "hello world !", seller_comment: "ok bro")}
  let!(:appointment2) { Appointment.create!(start_date: Time.now + 1.day, end_date: Time.now + 1.day + service.time.minutes, seller: seller, customer: customer, comment: "hello world 2!", seller_comment: "ok bro")}

  subject { Appointment.new(start_date: Time.now + 1.day, end_date: Time.now + 1.day + service.time.minutes, seller: seller, customer: customer, comment: "hello world 2!", seller_comment: "ok bro")}

  it "2 appointments created for seller" do
    expect(seller.appointments.count).to eq 2
  end

  it "2 appointments created for customer" do
    expect(customer.appointments.count).to eq 2
  end

  it "Availability separated on appointment status accepted" do
    appointment1.update(status: "accepted")
    expect(seller.availabilities.count).to eq 3
  end

  it "Availability restore after appointment canceled" do
    appointment2.update(status: "accepted")
    expect(seller.availabilities.count).to eq 3
    appointment2.update(status: "canceled")
    expect(seller.availabilities.count).to eq 1
  end

  it "Appointment is not include in availability range" do
    subject.start_date = Time.now + 10.days
    subject.end_date = subject.start_date + service.time.minutes
    expect(subject).to_not be_valid
    expect(subject.errors[:availability]).to include('Les dates de début et de fin doivent être incluses dans un créneau de disponibilité.')
  end
end
