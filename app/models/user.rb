class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :validatable,
         :jwt_authenticatable, :confirmable, :lockable, jwt_revocation_strategy: self

  has_many :apointments

  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :entreprise, presence: true

  enum role: {
    user: 0,
    admin: 1
  }
end
