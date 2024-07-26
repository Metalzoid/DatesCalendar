class DeleteAdminIdToAppointment < ActiveRecord::Migration[7.1]
  def change
    remove_column :appointments, :admin_id
  end
end
