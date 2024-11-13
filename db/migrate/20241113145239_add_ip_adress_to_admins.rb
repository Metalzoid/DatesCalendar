class AddIpAdressToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :ip_address, :string
  end
end
