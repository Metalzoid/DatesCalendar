class AddDisabledToServices < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :disabled, :boolean, default: false
  end
end
