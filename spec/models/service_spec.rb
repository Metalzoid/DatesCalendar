require 'rails_helper'

RSpec.describe Service, type: :model do
  let(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end
  let(:user) { User.create(email: "user@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let!(:services) do
    (0..4).map do |i|
      Service.create(title: "service#{i}", price: rand(1..100), time: rand(1..100), user: user)
    end
  end
  subject { Service.new(title: "service", price: 15, time: 30, user: user) }

  it "5 services created" do
    expect(user.services.count).to eq 5
  end

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without title" do
    subject.title = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without price" do
    subject.price = nil
    expect(subject).to_not be_valid
  end

  it "price is a float" do
    expect(subject.price.class).to eq Float
  end

  it "time is a integer" do
    subject.time = 14.5
    expect(subject.time.class).to eq Integer
  end

  it "is not valid without time" do
    subject.time = nil
    expect(subject).to_not be_valid
  end

  it "Can get list of availabilities from Admin" do
    expect(Service.by_admin(admin)).to be_a(ActiveRecord::Relation)
    expect(Service.by_admin(admin).count).to eq 5
  end
end
