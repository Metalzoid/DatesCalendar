class ModifyBuyerToClientOnAppointment < ActiveRecord::Migration[7.1]
  def change
    rename_column :appointments, :buyer_id, :client_id
  end
end
