class CreateServices < ActiveRecord::Migration[7.1]
  def change
    create_table :services do |t|
      t.string :title
      t.float :price
      t.references :user, null: false, foreign_key: true
      t.integer :time

      t.timestamps
    end
  end
end
