class AddClientIdToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :client_id, :integer, null: false
    add_index :appointments, :client_id
    add_foreign_key :appointments, :users, column: :client_id, primary_key: :id
  end
end
