require 'rails_helper'

RSpec.describe Admin, type: :model do
  subject { Admin.new(email: "admin@test.fr", password: "azerty") }
  let(:user1) { User.new(email: "user1@test.fr", password: "azerty", role: "both", admin: subject) }
  let(:user2) { User.new(email: "user2@test.fr", password: "azerty", role: "both", admin: subject) }
  let(:user3) { User.new(email: "user3@test.fr", password: "azerty", role: "both", admin: subject) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without email" do
    subject.email=nil
    expect(subject).to_not be_valid
  end

  it "is not valid without password" do
    subject.password=nil
    expect(subject).to_not be_valid
  end

  it "has an api_key" do
    subject.skip_confirmation!
    subject.save
    expect(subject.api_key.api_key.class).to eq String
  end

  it "has multiple users" do
    subject.skip_confirmation!
    subject.save
    user1.save
    user2.save
    user3.save
    expect(subject.users.count).to eq 3
  end

  it "has a scope by_admin" do
    subject.skip_confirmation!
    subject.save
    user1.save
    user2.save
    user3.save
    result = User.by_admin(subject)

    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to include(user1, user2, user3)
  end
end
