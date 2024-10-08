# frozen_string_literal: true

class CreateAppointmentServices < ActiveRecord::Migration[7.1]
  def change
    create_table :appointment_services do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true

      t.timestamps
    end
  end
end
