class AddEntrepriseToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :entreprise, :string
  end
end
