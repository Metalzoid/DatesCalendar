require 'rails_helper'

RSpec.describe AvailabilityOverlapService, type: :service do
  let!(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end

  let!(:user) { User.create(email: "user@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "both", admin: admin) }
  let(:base_time) { Time.parse("2025-01-01 10:00:00") }

  describe '#call' do
    context 'when there are no overlapping availabilities' do
      let!(:availability) { Availability.new(start_date: base_time + 1.hour, end_date: base_time + 2.hours, available: true, user: user) }

      it 'returns the original availability' do
        service = AvailabilityOverlapService.new(availability)
        result = service.call
        expect(result).to eq([availability])
      end
    end

    context 'when there are overlapping availabilities of same type' do
      let!(:existing_availability) { Availability.create!(start_date: base_time + 1.hour, end_date: base_time + 2.hours, available: true, user: user) }
      let!(:new_availability) { Availability.new(start_date: base_time + 1.5.hours, end_date: base_time + 2.5.hours, available: true, user: user) }

      it 'destroys the existing availability and keeps the new one' do
        overlapping = [existing_availability]
        service = AvailabilityOverlapService.new(new_availability, overlapping)

        expect { service.call }.to change { Availability.count }.by(-1)
        expect(existing_availability.destroyed?).to be true
      end
    end

    context 'when there are overlapping availabilities of different types' do
      let!(:existing_availability) { Availability.create!(start_date: base_time + 1.hour, end_date: base_time + 3.hours, available: true, user: user) }
      let!(:new_availability) { Availability.new(start_date: base_time + 1.5.hours, end_date: base_time + 2.5.hours, available: false, user: user) }

      it 'handles partial overlap correctly' do
        overlapping = [existing_availability]
        service = AvailabilityOverlapService.new(new_availability, overlapping)
        result = service.call

        expect(result.length).to be >= 1
        expect(result).to include(new_availability)
      end
    end

    context 'when new availability completely englobes existing one' do
      let!(:existing_availability) { Availability.create!(start_date: base_time + 1.5.hours, end_date: base_time + 2.5.hours, available: false, user: user) }
      let!(:new_availability) { Availability.new(start_date: base_time + 1.hour, end_date: base_time + 3.hours, available: true, user: user) }

      it 'creates additional availability after the existing one' do
        overlapping = [existing_availability]
        service = AvailabilityOverlapService.new(new_availability, overlapping)
        result = service.call

        expect(result.length).to eq(2)
        expect(result).to include(new_availability)

        # Should have created a new availability after the existing one
        new_after_availability = result.find { |av| av != new_availability }
        expect(new_after_availability.start_date).to eq(existing_availability.end_date)
        expect(new_after_availability.end_date).to eq(base_time + 3.hours) # Use base_time instead of new_availability.end_date
        expect(new_after_availability.available).to eq(new_availability.available)
      end
    end
  end
end
