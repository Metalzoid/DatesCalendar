class UpdateAdmins < ActiveRecord::Migration[7.1]
  def change
    add_column(:admins, :provider, :string, limit: 50, null: false, default:'')
    add_column(:admins, :uid, :string, limit: 50, null: false, default:'')
  end
end
