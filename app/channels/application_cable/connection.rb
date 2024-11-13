# frozen_string_literal: true
require 'pry-byebug'
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
    def find_verified_user
      puts cookies.signed["user.id"]
      if cookies.signed["user.id"].present?
        user = User.find_by(id: cookies.signed["user.id"])
        user || reject_unauthorized_connection
      else
        reject_unauthorized_connection
      end
    end

  end
end
