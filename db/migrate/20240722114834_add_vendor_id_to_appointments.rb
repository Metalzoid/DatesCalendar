class AddVendorIdToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :vendor_id, :integer, null: false
    add_index :appointments, :vendor_id
    add_foreign_key :appointments, :users, column: :vendor_id, primary_key: :id
  end
end
