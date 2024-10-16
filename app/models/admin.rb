# frozen_string_literal: true

# Admin Model
class Admin < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, :jwt_authenticatable, :confirmable,
         jwt_revocation_strategy: self, omniauth_providers: [:google_oauth2]
  has_many :users, dependent: :destroy
  has_one :api_key, dependent: :destroy
  after_create :init_api_key

  def self.from_omniauth(auth)
    admin = Admin.where(email: auth.info.email).first

    if admin
      admin.provider = auth.provider
      admin.uid = auth.uid
      admin.save
    else
      admin = where(provider: auth.provider, uid: auth.uid).first_or_create do |new_admin|
        new_admin.email = auth.info.email
        new_admin.password = Devise.friendly_token[0, 20]
        new_admin.skip_confirmation!
      end
    end

    admin
  end

  def init_api_key
    ApiKey.create!(admin: self)
  end
end
