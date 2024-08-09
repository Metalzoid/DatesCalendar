# frozen_string_literal: true

class Appointment < ApplicationRecord
  after_commit :after_commit_actions, unless: :skip_after_commit_actions?

  belongs_to :customer, class_name: 'User'
  belongs_to :seller, class_name: 'User'
  has_many :appointment_services, dependent: :destroy
  has_many :services, through: :appointment_services

  validates :start_date, presence: true, comparison: { greater_than: Time.now }
  validates :end_date, comparison: { greater_than: :start_date }, presence: true
  validates :comment, presence: true, length: { maximum: 500 }
  validates :customer_id, presence: true
  validates :seller_id, presence: true
  validate :check_availability

  enum status: { hold: 0, accepted: 1, finished: 2, canceled: 3 }

  def mailer_customer(params = {}, from_controller: false)
    @template_uuid = params[:template_uuid] || determine_customer_template_uuid
    return if @template_uuid.nil?

    MailtrapJob.perform_later(
      template_uuid: @template_uuid,
      template_variables: determine_template_vars_customer(from_controller, params),
      to_email: customer.email
    )
  end

  def mailer_seller(params = {}, from_controller: false)
    @template_uuid = params[:template_uuid] || determine_seller_template_uuid
    return if @template_uuid.nil?

    MailtrapJob.perform_later(
      template_uuid: @template_uuid,
      template_variables: determine_template_vars_seller(from_controller, params),
      to_email: seller.email
    )
  end

  def update_price
    new_price = services.sum(&:price)
    update(price: new_price)
  end

  private

  def after_commit_actions
    return if destroyed?

    ActiveRecord::Base.transaction do
      create_availability if status == 'accepted'
      if ENV.fetch('USE_MAILTRAP') == 'true'
        mailer_customer
        mailer_seller
      end
      update(status: 0) if status.nil?
    end
  end

  def skip_after_commit_actions?
    saved_change_to_price? || destroyed?
  end

  def determine_template_vars_seller(from_controller, params)
    @template_vars_seller = {
      firstname: seller.firstname,
      lastname: seller.lastname,
      message: seller_comment || '',
      comment: comment || '',
      start_date: transform_date(start_date),
      end_date: transform_date(end_date),
      created_at: transform_date(created_at),
      customer: "#{customer.firstname.capitalize} #{customer.lastname.capitalize}",
      link: 'test.fr/dashboard'
    }
    if from_controller && params[:update].present?
      params[:update].each do |key, value|
        template_vars[key] = transform_date(value)
      end
    end
    @template_vars_seller
  end

  def determine_template_vars_customer(from_controller, params)
    @template_vars_customer = {
      firstname: customer.firstname,
      lastname: customer.lastname,
      seller: "#{seller.firstname.capitalize} #{seller.lastname.capitalize}",
      message: seller_comment || '',
      comment: comment || '',
      start_date: transform_date(start_date),
      end_date: transform_date(end_date),
      created_at: transform_date(created_at),
      link: 'test.fr/dashboard'
    }
    if from_controller && params[:update].present?
      params[:update].each do |key, value|
        template_vars[key] = transform_date(value)
      end
    end
    @template_vars_customer
  end

  #### Determine Mailtrap template UUID for customer email ####
  def determine_customer_template_uuid
    if status.nil?
      '3e4c9e12-c352-491a-a6ee-5f967263b92c'
    else
      case status
      when 'accepted' then '49d126b2-d0a7-45a5-a237-ebc66a1cf503'
      when 'finished' then '363b50b7-0689-4e53-872f-04df9ffb2063'
      when 'canceled' then '0de9b64b-4d35-4a60-b9a9-b3b508d34e60'
      end
    end
  end

  #### Determine Mailtrap template UUID for seller email ####
  def determine_seller_template_uuid
    if status.nil?
      '7532b4fe-6346-41cc-9edb-e5f7ec75fa29'
    else
      case status
      when 'accepted' then 'd986b954-3dc0-4f18-a3ba-4ea15f5a7778'
      when 'finished' then 'bb50996b-7744-4087-8657-345a8f8aa0d9'
      when 'canceled' then 'c6585d13-3c1f-44e5-bc76-665db9068772'
      end
    end
  end

  def transform_date(date)
    I18n.l(date, format: :custom)
  end

  def check_availability
    return unless status == 'hold' || status.nil?

    availabilities = Availability.where(available: true)
    overlapping_availability = availabilities.any? do |availability|
      start_date >= availability.start_date && end_date <= availability.end_date
    end
    return if overlapping_availability

    errors.add(:availability,
               'Les dates de début et de fin doivent être incluses dans une plage de disponibilité valide.')
  end

  def create_availability
    return unless status == 'accepted'

    Availability.create!(start_date:, end_date:, available: false,
                         user: seller)
  end
end
