class ModifyAdminCommentToVendorComment < ActiveRecord::Migration[7.1]
  def change
    rename_column :appointments, :admin_comment, :vendor_comment
  end
end
