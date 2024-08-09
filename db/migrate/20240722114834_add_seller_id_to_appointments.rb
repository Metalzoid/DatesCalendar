# frozen_string_literal: true

class AddSellerIdToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :seller_id, :integer, null: false
    add_index :appointments, :seller_id
    add_foreign_key :appointments, :users, column: :seller_id, primary_key: :id
  end
end
