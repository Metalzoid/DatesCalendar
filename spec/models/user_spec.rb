require 'rails_helper'

RSpec.describe User, type: :model do
  let(:admin) { Admin.new(email: "admin@test.fr", password: "azerty") }
  subject { User.new(email: "user@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }

  it "is valid with valid attributes" do
    admin.skip_confirmation!
    admin.save
    expect(subject).to be_valid
  end

  it "is not valid without email" do
    subject.email = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without password" do
    subject.password = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without role" do
    subject.role = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without a valid role" do
    expect { subject.role = "vendeur" }.to raise_error(ArgumentError)
  end
end
