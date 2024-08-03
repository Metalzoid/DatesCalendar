class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :validatable,
         :jwt_authenticatable, :confirmable, :lockable, jwt_revocation_strategy: self

  has_many :apointments
  has_many :services, dependent: :destroy
  has_many :availability

  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :company, presence: true

  enum role: {
    customer: 0,
    enterprise: 1,
    seller: 2
  }
end
