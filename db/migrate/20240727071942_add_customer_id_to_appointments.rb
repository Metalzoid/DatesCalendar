# frozen_string_literal: true

class AddCustomerIdToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :customer_id, :integer, null: false
    add_index :appointments, :customer_id
    add_foreign_key :appointments, :users, column: :customer_id, primary_key: :id
  end
end
