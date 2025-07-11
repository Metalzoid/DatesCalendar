require 'rails_helper'

RSpec.describe AvailabilityManagementService, type: :service do
  let!(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end

  let!(:user) { User.create(email: "user@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "seller", admin: admin) }
  let!(:service) { AvailabilityManagementService.new(user) }

  describe '#create_unavailability_for_appointment' do
    context 'when there is a covering availability' do
      let!(:availability) { Availability.create!(start_date: Time.now + 1.hour, end_date: Time.now + 5.hours, available: true, user: user) }

      it 'splits the availability and creates unavailability' do
        start_date = Time.now + 2.hours
        end_date = Time.now + 3.hours

        expect { service.create_unavailability_for_appointment(start_date, end_date) }
          .to change { user.availabilities.count }.by(2) # +3 nouvelles, -1 ancienne = +2

        # Vérifie qu'il y a une indisponibilité créée
        unavailability = user.availabilities.find_by(start_date: start_date, end_date: end_date, available: false)
        expect(unavailability).to be_present

        # Vérifie qu'il y a des disponibilités avant et après
        before_availability = user.availabilities.find_by(end_date: start_date, available: true)
        after_availability = user.availabilities.find_by(start_date: end_date, available: true)

        expect(before_availability).to be_present
        expect(after_availability).to be_present
      end
    end

    context 'when there is no covering availability' do
      it 'does nothing' do
        start_date = Time.now + 2.hours
        end_date = Time.now + 3.hours

        expect { service.create_unavailability_for_appointment(start_date, end_date) }
          .not_to change { user.availabilities.count }
      end
    end

    context 'with invalid time range' do
      it 'does nothing when start_date is after end_date' do
        expect { service.create_unavailability_for_appointment(Time.now + 3.hours, Time.now + 2.hours) }
          .not_to change { user.availabilities.count }
      end
    end
  end

  describe '#restore_availability_after_appointment_cancellation' do
    context 'when there are adjacent availabilities' do
      let!(:before_availability) { Availability.create!(start_date: Time.now + 1.hour, end_date: Time.now + 2.hours, available: true, user: user) }
      let!(:unavailability) { Availability.create!(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, available: false, user: user) }
      let!(:after_availability) { Availability.create!(start_date: Time.now + 3.hours, end_date: Time.now + 4.hours, available: true, user: user) }

      it 'merges the availabilities' do
        initial_count = user.availabilities.count
        service.restore_availability_after_appointment_cancellation(Time.now + 2.hours, Time.now + 3.hours)

        # Vérifie que la disponibilité avant a été étendue
        before_availability.reload
        expect(before_availability.end_date).to eq(Time.now + 4.hours)

        # Vérifie que les autres ont été supprimées
        expect(Availability.exists?(unavailability.id)).to be false
        expect(Availability.exists?(after_availability.id)).to be false
        expect(user.availabilities.count).to eq(initial_count - 2)
      end
    end

    context 'when there is only a before availability' do
      let!(:before_availability) { Availability.create!(start_date: Time.now + 1.hour, end_date: Time.now + 2.hours, available: true, user: user) }
      let!(:unavailability) { Availability.create!(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, available: false, user: user) }

      it 'extends the before availability' do
        initial_count = user.availabilities.count
        service.restore_availability_after_appointment_cancellation(Time.now + 2.hours, Time.now + 3.hours)

        before_availability.reload
        expect(before_availability.end_date).to eq(Time.now + 3.hours)
        expect(Availability.exists?(unavailability.id)).to be false
        expect(user.availabilities.count).to eq(initial_count - 1)
      end
    end

    context 'when there are no adjacent availabilities' do
      let!(:unavailability) { Availability.create!(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, available: false, user: user) }

      it 'creates a new availability' do
        initial_count = user.availabilities.count
        service.restore_availability_after_appointment_cancellation(Time.now + 2.hours, Time.now + 3.hours)

        # Vérifie qu'une nouvelle disponibilité a été créée
        new_availability = user.availabilities.find_by(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, available: true)
        expect(new_availability).to be_present
        expect(Availability.exists?(unavailability.id)).to be false
        expect(user.availabilities.count).to eq(initial_count) # -1 unavailability + 1 new availability = 0
      end
    end
  end

  describe '#save_availability_with_overlap_handling' do
    let!(:availability) { Availability.new(start_date: Time.now + 1.hour, end_date: Time.now + 2.hours, available: true, user: user) }

    context 'with valid availability' do
      it 'returns success' do
        result = service.save_availability_with_overlap_handling(availability)
        expect(result[:success]).to be true
        expect(result[:availabilities]).to be_present
      end
    end

    context 'with invalid availability' do
      let!(:invalid_availability) { Availability.new(start_date: nil, end_date: Time.now + 2.hours, available: true, user: user) }

      it 'returns failure' do
        result = service.save_availability_with_overlap_handling(invalid_availability)
        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end
    end
  end
end
