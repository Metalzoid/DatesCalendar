class AddNullFalseToVendorId < ActiveRecord::Migration[7.1]
  def change
    change_column_null :appointments, :vendor_id, false
  end
end
