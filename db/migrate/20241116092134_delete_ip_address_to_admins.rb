class DeleteIpAddressToAdmins < ActiveRecord::Migration[8.0]
  def change
    remove_column :admins, :ip_address
  end
end
