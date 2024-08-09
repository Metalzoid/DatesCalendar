# frozen_string_literal: true

# Model User
class User < ApplicationRecord
  include PgSearch::Model
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :validatable,
         :jwt_authenticatable, :confirmable, :lockable, jwt_revocation_strategy: self

  has_many :customer_appointments, class_name: 'Appointment', foreign_key: 'customer_id', dependent: :destroy
  has_many :seller_appointments, class_name: 'Appointment', foreign_key: 'seller_id', dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :availability, dependent: :destroy
  belongs_to :admin

  enum role: {
    customer: 0,
    seller: 1
  }

  validates :firstname, :lastname, :company, presence: true
  validates :role, presence: true, inclusion: { in: roles.keys }

  def appointments
    role == 'customer' ? Appointment.where(customer: self) : Appointment.where(seller: self)
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  pg_search_scope :search_by_firstname_and_lastname,
                  against: %i[firstname lastname],
                  using: {
                    tsearch: { prefix: true }
                  }
end
