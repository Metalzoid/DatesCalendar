class CreateApiKeys < ActiveRecord::Migration[7.1]
  def change
    create_table :api_keys do |t|
      t.string :api_key
      t.references :admin, null: false, foreign_key: true

      t.timestamps
    end
    add_index :api_keys, :api_key, unique: true
  end
end
