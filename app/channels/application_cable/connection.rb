# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
    def find_verified_user
      if cookies.request.params[:token].present?
        begin
          jwt_payload = JWT.decode(cookies.request.params[:token].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
          user = User.find(jwt_payload['sub'])
          user || reject_unauthorized_connection
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          # Capturer les erreurs liées au JWT ou si l'utilisateur n'est pas trouvé
          reject_unauthorized_connection
        end
      else
        reject_unauthorized_connection
      end
    end

  end
end
