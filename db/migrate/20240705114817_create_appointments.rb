class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.text :comment
      t.integer :status
      t.text :seller_comment
      t.float :price

      t.timestamps
    end
  end
end
