class AddEmailSentFlagsToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :email_sent_hold, :boolean, default: false, null: false
    add_column :appointments, :email_sent_accepted, :boolean, default: false, null: false
    add_column :appointments, :email_sent_finished, :boolean, default: false, null: false
    add_column :appointments, :email_sent_canceled, :boolean, default: false, null: false
  end
end
