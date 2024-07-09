class Availability < ApplicationRecord
  before_create :set_unavailable, unless: :skip_before_create

  validates :available, inclusion: [true, false]
  validates :start_date, presence: true
  validates :end_date, comparison: { greater_than: :start_date }, presence: true

  attr_accessor :skip_before_create

  def self.availabilities
    where(available: true).map do |availability|
      { from: availability.start_date, to: availability.end_date }
    end
  end

  def mailer(params = {})
    I18n.locale = :fr
    send_mail(
      template_uuid: params[:template_uuid],
      template_variables: {
        firstname: 'Valou',
        lastname: 'CDB',
        start_date: I18n.l(params[:start_date], format: :custom),
        end_date: I18n.l(params[:end_date], format: :custom),
        created_at: I18n.l(created_at, format: :custom)
      }
    )
  end

  def unavailable_update_mailer(params = {})
    I18n.locale = :fr
    send_mail(
      template_uuid: params[:template_uuid],
      template_variables: {
        firstname: 'Valou',
        lastname: 'CDB',
        old_start_date: I18n.l(params[:old_start_date], format: :custom),
        old_end_date: I18n.l(params[:old_end_date], format: :custom),
        cur_start_date: I18n.l(params[:cur_start_date], format: :custom),
        cur_end_date: I18n.l(params[:cur_end_date], format: :custom),
        new_start_date: I18n.l(params[:new_start_date], format: :custom),
        new_end_date: I18n.l(params[:new_end_date], format: :custom)
      }
    )
  end

  private

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

  def set_unavailable
    current_availability = Availability.where("start_date <= ? AND end_date >= ? AND available = ?", start_date, end_date, true)
    return if current_availability.empty? || available

    current_availability.each do |cur|
      new_availability = Availability.new(start_date: end_date, end_date: cur.end_date, available: true)
      new_availability.skip_before_create = true
      new_availability.save!

      unavailable_update_mailer(
        old_start_date: cur.start_date,
        old_end_date: cur.end_date,
        cur_start_date: cur.start_date,
        cur_end_date: start_date,
        new_start_date: end_date,
        new_end_date: cur.end_date,
        template_uuid: '825c3c39-49d7-4c6e-b72d-bf07d62a74ad'
      )

      cur.update(end_date: start_date)
    end
  end
end
