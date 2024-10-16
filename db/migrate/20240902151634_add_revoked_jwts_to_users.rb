class AddRevokedJwtsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :revoked_jwts, :jsonb, default: []
  end
end
