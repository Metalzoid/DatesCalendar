require 'rails_helper'

RSpec.describe Availability, type: :model do
  let!(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end
  let!(:user) { User.create(email: "user@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let!(:availability1) { Availability.create!(start_date: (Time.now + 5.minutes), end_date: (Time.now + 1.hour), available: true, user: user) }
  let!(:availability2) { Availability.create!(start_date: (Time.now + 1.hours + 1.minutes), end_date: (Time.now + 2.hours), available: false, user: user) }
  let!(:availability3) { Availability.create!(start_date: (Time.now + 2.hours + 1.minutes), end_date: (Time.now + 3.hours), available: true, user: user) }
  let!(:availability4) { Availability.create!(start_date: (Time.now + 3.hours + 1.minutes), end_date: (Time.now + 4.hours), available: [true, false].sample, user: user) }
  let!(:availability5) { Availability.create!(start_date: (Time.now + 4.hours + 1.minutes), end_date: (Time.now + 5.hours), available: [true, false].sample, user: user) }

  subject { Availability.new(start_date: (Time.now + 1.hour), end_date: (Time.now + 2.hours), available: true, user: user) }

  it "5 availability created" do
    expect(user.availabilities.count).to eq 5
  end

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without start_date" do
    subject.start_date = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without end_date" do
    subject.end_date = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without available" do
    subject.available = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without user" do
    subject.user = nil
    expect(subject).to_not be_valid
  end

  it "end_date can't be earlier than start_date" do
    subject.end_date = Time.now - 1.hour
    expect(subject).to_not be_valid
  end

  it "Can get list of availabilities from Admin" do
    expect(Availability.by_admin(admin)).to be_a(ActiveRecord::Relation)
    expect(Availability.by_admin(admin).count).to eq 5
  end

  it "Availability with same status and overlapping is combined" do
    expect(user.availabilities.count).to eq 5
    Availability.create!(start_date: (Time.now + 1.day + 1.hour), end_date: (Time.now + 1.day + 2.hour), available: true, user: user)
    Availability.create!(start_date: (Time.now + 1.day + 2.hour + 1.minute), end_date: (Time.now + 1.day + 3.hour), available: true, user: user)
    Availability.create!(start_date: (Time.now + 1.day), end_date: (Time.now + 1.day + 4.hour), available: true, user: user)
    expect(user.availabilities.count).to eq 6
  end

  it "Availability with different status and overlapping is correctly seperate with 1 overlapped" do
    expect(user.availabilities.count).to eq 5
    Availability.create!(start_date: (Time.now + 1.day + 2.hour).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 3.hour).strftime("%Y%m%d%H%M"), available: false, user: user)
    Availability.create!(start_date: (Time.now + 1.day).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 4.hour).strftime("%Y%m%d%H%M"), available: true, user: user)
    expect(user.availabilities.count).to eq 8
    expect(user.availabilities.where(start_date: (Time.now + 1.day).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 2.hour).strftime("%Y%m%d%H%M"), available: true).count).to eq 1
    expect(user.availabilities.where(start_date: (Time.now + 1.day + 2.hour).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 3.hour).strftime("%Y%m%d%H%M"), available: false).count).to eq 1
    expect(user.availabilities.where(start_date: (Time.now + 1.day + 3.hour).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 4.hour).strftime("%Y%m%d%H%M"), available: true).count).to eq 1
  end

  it "Availability with different status and overlapping is correctly seperate with 2 overlapped" do
    expect(user.availabilities.count).to eq 5
    Availability.create!(start_date: (Time.now + 1.day + 2.hour).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 2.hour + 15.minutes).strftime("%Y%m%d%H%M"), available: false, user: user)
    Availability.create!(start_date: (Time.now + 1.day + 2.hour + 45.minutes).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 3.hour).strftime("%Y%m%d%H%M"), available: false, user: user)
    Availability.create!(start_date: (Time.now + 1.day).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 4.hour).strftime("%Y%m%d%H%M"), available: true, user: user)
    expect(user.availabilities.count).to eq 10
    expect(user.availabilities.where(start_date: (Time.now + 1.day).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 2.hour).strftime("%Y%m%d%H%M"), available: true).count).to eq 1
    expect(user.availabilities.where(start_date: (Time.now + 1.day + 2.hour).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 2.hour + 15.minutes).strftime("%Y%m%d%H%M"), available: false).count).to eq 1
    expect(user.availabilities.where(start_date: (Time.now + 1.day + 2.hour + 15.minutes).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 2.hour + 45.minutes).strftime("%Y%m%d%H%M"), available: true).count).to eq 1
    expect(user.availabilities.where(start_date: (Time.now + 1.day + 2.hour + 45.minutes).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 3.hour).strftime("%Y%m%d%H%M"), available: false).count).to eq 1
    expect(user.availabilities.where(start_date: (Time.now + 1.day + 3.hour).strftime("%Y%m%d%H%M"), end_date: (Time.now + 1.day + 4.hour).strftime("%Y%m%d%H%M"), available: true).count).to eq 1
  end
end
