# frozen_string_literal: true

class AddAdminIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :admin, null: false, foreign_key: true
  end
end
