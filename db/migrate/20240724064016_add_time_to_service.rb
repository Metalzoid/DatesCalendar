class AddTimeToService < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :time, :integer
  end
end
