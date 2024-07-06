class Availability < ApplicationRecord
  before_create :set_unavailable, unless: :skip_before_create

  validates :available, inclusion: [true, false]
  validates :start_date, presence: true
  validates :end_date, comparison: { greater_than: :start_date },
                       presence: true

  attr_accessor :skip_before_create

  def self.availabilities
    self.where(available: true).map do |availability|
      { from: availability.start_date, to: availability.end_date }
    end
  end

  private

  def mailer(params = {})
    I18n.locale = :fr
    mail = Mailtrap::Mail::FromTemplate.new(
      from: { email: 'from@demomailtrap.com', name: 'Valou Coiffure' },
      to: [
        { email: 'gagnaire.flo@gmail.com' }
      ],
      template_uuid: params[:template_uuid],
      template_variables: {
        firstname: 'Valou',
        lastname: 'CDB',
        start_date: I18n.l(params[:start_date], format: :custom),
        end_date: I18n.l(params[:end_date], format: :custom),
        created_at: I18n.l(self.created_at, format: :custom)
      }
    )
    client = Mailtrap::Client.new()
    client.send(mail)
  end

  def unavailable_update_mailer(params = {})
    I18n.locale = :fr
    mail = Mailtrap::Mail::FromTemplate.new(
      from: { email: 'from@demomailtrap.com', name: 'Valou Coiffure' },
      to: [
        { email: 'gagnaire.flo@gmail.com' }
      ],
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
    client = Mailtrap::Client.new()
    client.send(mail)
  end

  def set_unavailable
    current_availability = Availability.where(["start_date <= ? and end_date >= ? and available = ?", self.start_date, self.end_date, true])
    if current_availability.size > 0 && self.available == false
      current_availability.each do |cur|
        new_availability = Availability.new(start_date: self.end_date, end_date: cur.end_date, available: true)
        new_availability.skip_before_create = true
        new_availability.save!
        unavailable_update_mailer({old_start_date: cur.start_date, old_end_date: cur.end_date, cur_start_date: cur.start_date, cur_end_date: self.start_date, new_start_date: self.end_date, new_end_date: cur.end_date, template_uuid: '825c3c39-49d7-4c6e-b72d-bf07d62a74ad'})
        cur.update(end_date: self.start_date)
        break
      end
    elsif self.available == true
      mailer({start_date: self.start_date, end_date: self.end_date, template_uuid: 'd2f2779b-3b07-4770-85a1-f86a06d8e62b'})
    elsif self.available == false
      mailer({start_date: self.start_date, end_date: self.end_date, template_uuid: 'eff70055-6107-4bee-9c08-ad829db8dcd4'})
    end
  end
end
