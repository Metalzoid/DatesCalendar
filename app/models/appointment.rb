require 'mailtrap'
require 'i18n'

class Appointment < ApplicationRecord
  after_commit :after_save_actions

  belongs_to :client, class_name: 'User'
  belongs_to :vendor, class_name: 'User'
  has_many :appointment_services, dependent: :destroy

  validates :start_date, presence: true, comparison: { greater_than: Date.today }
  validates :end_date, comparison: { greater_than: :start_date }, presence: true
  validates :comment, presence: true, length: { maximum: 500 }
  validates :client_id, presence: true
  validates :vendor_id, presence: true
  validate :check_availability

  enum status: {
    hold: 0,
    accepted: 1,
    finished: 2,
    canceled: 3
  }

  def mailer_update(params = {})
    I18n.locale = :fr
    send_mail(
      template_uuid: params[:template_uuid],
      template_variables: {
        firstname: params[:firstname],
        lastname: params[:lastname],
        link: "http://localhost/dashboard/",
        message: params[:vendor_comment] || '',
        old_start_date: I18n.l(params[:old_start_date], format: :custom),
        old_end_date: I18n.l(params[:old_end_date], format: :custom),
        new_start_date: I18n.l(params[:new_start_date], format: :custom),
        new_end_date: I18n.l(params[:new_end_date], format: :custom),
        client: "#{params[:client_firstname]} #{params[:client_lastname]}"
      }
    )
  end

  def update_price
    total_price = appointment_services.sum { |appointment_service| appointment_service.service.price }
    update_column(:price, total_price)
  end

  private

  def after_save_actions
    ActiveRecord::Base.transaction do
      create_availability
      # mailer_user
      # mailer_admin
    end
  end

  def check_availability
    availabilities = Availability.where(available: true)
    overlapping_availability = availabilities.any? do |availability|
      (start_date >= availability.start_date && end_date <= availability.end_date)
    end
    unless overlapping_availability
      errors.add(:availability, 'Les dates de début et de fin doivent être incluses dans une plage de disponibilité valide.')
    end
  end

  def mailer_admin
    I18n.locale = :fr
    template_uuid = determine_admin_template_uuid
    return if template_uuid.nil?
    send_mail(
      template_uuid: template_uuid,
      template_variables: {
        firstname: vendor.firstname,
        lastname: vendor.lastname,
        start_date: I18n.l(start_date, format: :custom),
        end_date: I18n.l(end_date, format: :custom),
        created_at: I18n.l(created_at, format: :custom),
        link: "http://localhost/reservation/#{id}",
        user: "#{client.firstname.capitalize} #{client.lastname.capitalize}"
      }
    )
  end

  def mailer_user
    I18n.locale = :fr
    template_uuid = determine_user_template_uuid
    return if template_uuid.nil?

    send_mail(
      template_uuid: template_uuid,
      template_variables: {
        firstname: client.firstname,
        lastname: client.lastname,
        start_date: I18n.l(start_date, format: :custom),
        end_date: I18n.l(end_date, format: :custom),
        created_at: I18n.l(created_at, format: :custom),
        link: "http://localhost/dashboard/",
        message: vendor_comment || ""
      }
    )
  end

  def send_mail(template_uuid:, template_variables:)
    mail = Mailtrap::Mail::FromTemplate.new(
      from: { email: 'from@demomailtrap.com', name: 'Valou Coiffure' },
      to: [{ email: 'gagnaire.flo@gmail.com' }],
      template_uuid: template_uuid,
      template_variables: template_variables
    )
    client = Mailtrap::Client.new
    client.send(mail)
  end

  def determine_admin_template_uuid
    if status.nil?
      update_column(:status, 0)
      "7532b4fe-6346-41cc-9edb-e5f7ec75fa29"
    else
      case status
      when "accepted" then "d986b954-3dc0-4f18-a3ba-4ea15f5a7778"
      when "finished" then "bb50996b-7744-4087-8657-345a8f8aa0d9"
      when "canceled" then "c6585d13-3c1f-44e5-bc76-665db9068772"
      else nil
      end
    end
  end

  def determine_user_template_uuid
    if status.nil?
      "3e4c9e12-c352-491a-a6ee-5f967263b92c"
    else
      case status
      when "accepted" then "49d126b2-d0a7-45a5-a237-ebc66a1cf503"
      when "finished" then "363b50b7-0689-4e53-872f-04df9ffb2063"
      when "canceled" then "0de9b64b-4d35-4a60-b9a9-b3b508d34e60"
      else nil
      end
    end
  end

  def create_availability
    Availability.create!(start_date: start_date, end_date: end_date, available: false, user: vendor) if status == 'accepted'
  end
end
