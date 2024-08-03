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
  validates :entreprise, presence: true

  enum role: {
    client: 0,
    enterprise: 1,
    vendor: 2,
    admin: 3
  }

  def admin?
    return true if role == 'admin'
    false
  end
end
