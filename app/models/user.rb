class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :validatable,
         :jwt_authenticatable, :confirmable, :lockable, jwt_revocation_strategy: self

  has_many :apointments
  has_many :services, dependent: :destroy

  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :entreprise, presence: true

  enum role: {
    client: 0,
    vendor: 1,
    admin: 2
  }
end
