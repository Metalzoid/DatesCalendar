# frozen_string_literal: true

# User Model
class User < ApplicationRecord
  include PgSearch::Model
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
         :jwt_authenticatable, :lockable, jwt_revocation_strategy: self

  has_many :customer_appointments, class_name: 'Appointment', foreign_key: 'customer_id', dependent: :destroy
  has_many :seller_appointments, class_name: 'Appointment', foreign_key: 'seller_id', dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :availabilities, dependent: :destroy
  belongs_to :admin

  scope :by_admin, ->(admin) { where(admin:) }

  enum role: {
    customer: 0,
    seller: 1,
    both: 2
  }

  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :admin_id, presence: true

  def appointments
    role == 'customer' ? Appointment.where(customer: self) : Appointment.where(seller: self)
  end

  def full_name_with_id
    "#{id} - #{firstname} #{lastname}"
  end

  def revoke_jwt(payload)
    revoked_jwts << payload['jti']
    save!
  end

  def jwt_revoked?(payload)
    revoked_jwts.include?(payload['jti'])
  end

  pg_search_scope :search_by_firstname_and_lastname,
                  against: %i[firstname lastname],
                  using: {
                    tsearch: { prefix: true }
                  }
end
