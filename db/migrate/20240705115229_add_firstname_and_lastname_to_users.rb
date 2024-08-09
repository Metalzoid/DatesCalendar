# frozen_string_literal: true

class AddFirstnameAndLastnameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :firstname, :string
    add_column :users, :lastname, :string
  end
end
