# frozen_string_literal: true

# Model User
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

  scope :by_admin, ->(admin) { where(admin: admin) }

  enum role: {
    customer: 0,
    seller: 1,
    both: 2
  }

  validates :firstname, :lastname, :company, presence: true
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :admin_id, presence: true

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
