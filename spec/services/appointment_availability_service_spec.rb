require 'rails_helper'

RSpec.describe AppointmentAvailabilityService, type: :service do
  let!(:admin) do
    admin = Admin.new(email: "admin@test.fr", password: "azerty")
    admin.skip_confirmation!
    admin.save
    admin
  end

  let!(:seller) { User.create(email: "seller@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "seller", admin: admin) }
  let!(:customer) { User.create(email: "customer@test.fr", password: "azerty", firstname: "firstnameTest", lastname: "lastnameTest", phone_number: "01 02 03 04 05", role: "customer", admin: admin) }

  describe '#validate_appointment_availability' do
    context 'when appointment is within available slot' do
      let!(:availability) { Availability.create!(start_date: Time.now + 1.hour, end_date: Time.now + 5.hours, available: true, user: seller) }
      let!(:appointment) { Appointment.new(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, seller: seller, customer: customer, comment: "Test") }

      it 'returns true' do
        service = AppointmentAvailabilityService.new(appointment)
        expect(service.validate_appointment_availability).to be true
      end
    end

    context 'when appointment is outside available slots' do
      let!(:appointment) { Appointment.new(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, seller: seller, customer: customer, comment: "Test") }

      it 'returns false and adds error' do
        service = AppointmentAvailabilityService.new(appointment)
        expect(service.validate_appointment_availability).to be false
        expect(appointment.errors[:availability]).to include('Les dates de début et de fin doivent être incluses dans un créneau de disponibilité.')
      end
    end

    context 'when appointment is existing record' do
      let!(:availability) { Availability.create!(start_date: Time.now + 1.hour, end_date: Time.now + 5.hours, available: true, user: seller) }
      let!(:appointment) { Appointment.create!(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, seller: seller, customer: customer, comment: "Test") }

      it 'returns true for existing records' do
        service = AppointmentAvailabilityService.new(appointment)
        expect(service.validate_appointment_availability).to be true
      end
    end
  end

  describe '#handle_appointment_acceptance' do
    let!(:availability) { Availability.create!(start_date: Time.now + 1.hour, end_date: Time.now + 5.hours, available: true, user: seller) }

    context 'when appointment is accepted' do
      let!(:appointment) { Appointment.create!(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, seller: seller, customer: customer, comment: "Test", status: :accepted) }

      it 'creates unavailability when appointment is accepted' do
        initial_count = seller.availabilities.count
        service = AppointmentAvailabilityService.new(appointment)
        service.handle_appointment_acceptance

        # Vérifie qu'une indisponibilité a été créée
        unavailability = seller.availabilities.find_by(
          start_date: appointment.start_date,
          end_date: appointment.end_date,
          available: false
        )
        expect(unavailability).to be_present

        # Vérifie qu'il y a maintenant 3 créneaux (before, unavailable, after)
        expect(seller.availabilities.count).to eq(initial_count + 2)
      end
    end

    context 'when appointment is not accepted' do
      let!(:appointment) { Appointment.create!(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, seller: seller, customer: customer, comment: "Test", status: :hold) }

      it 'does not create unavailability' do
        service = AppointmentAvailabilityService.new(appointment)

        expect { service.handle_appointment_acceptance }
          .not_to change { seller.availabilities.count }
      end
    end
  end

  describe '#handle_appointment_status_change_from_accepted' do
    let!(:before_availability) { Availability.create!(start_date: Time.now + 1.hour, end_date: Time.now + 2.hours, available: true, user: seller) }
    let!(:unavailability) { Availability.create!(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, available: false, user: seller) }
    let!(:after_availability) { Availability.create!(start_date: Time.now + 3.hours, end_date: Time.now + 4.hours, available: true, user: seller) }

    context 'when previous status was accepted' do
      # Créer le rendez-vous sans validation car les disponibilités existent déjà
      let!(:appointment) do
        appt = Appointment.new(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, seller: seller, customer: customer, comment: "Test", status: :canceled)
        appt.save(validate: false)
        appt
      end

      it 'restores availability when previous status was accepted' do
        service = AppointmentAvailabilityService.new(appointment)
        initial_count = seller.availabilities.count

        service.handle_appointment_status_change_from_accepted('accepted')

        # Vérifie que les disponibilités ont été fusionnées
        before_availability.reload
        expect(before_availability.end_date).to eq(after_availability.end_date)
        expect(Availability.exists?(unavailability.id)).to be false
        expect(Availability.exists?(after_availability.id)).to be false
        expect(seller.availabilities.count).to eq(initial_count - 2)
      end
    end

    context 'when previous status was not accepted' do
      let!(:appointment) do
        appt = Appointment.new(start_date: Time.now + 2.hours, end_date: Time.now + 3.hours, seller: seller, customer: customer, comment: "Test", status: :canceled)
        appt.save(validate: false)
        appt
      end

      it 'does not restore availability' do
        service = AppointmentAvailabilityService.new(appointment)

        expect { service.handle_appointment_status_change_from_accepted('hold') }
          .not_to change { seller.availabilities.count }
      end
    end
  end
end
