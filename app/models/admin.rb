# frozen_string_literal: true

# Model Admin
class Admin < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, :jwt_authenticatable,
         jwt_revocation_strategy: self, omniauth_providers: [:github, :google_oauth2]
  has_many :users, dependent: :destroy
  has_one :api_key, dependent: :destroy
  after_create :init_api_key

  def self.create_from_provider_data(provider_data)
    where(provider: provider_data.provider, uid: provider_data.uid).first_or_create  do |admin|
      admin.email = provider_data.info.email
      admin.password = Devise.friendly_token[0, 20]
    end
  end

  def init_api_key
    ApiKey.create!(admin: self)
  end
end
