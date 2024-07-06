class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.text :comment
      t.integer :status
      t.text :admin_comment
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
