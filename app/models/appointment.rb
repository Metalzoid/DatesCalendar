require 'mailtrap'
require 'i18n'
class Appointment < ApplicationRecord
  after_save :create_availability
  after_save :mailer_admin
  after_save :mailer_user

  belongs_to :user

  validates :start_date, presence: true, comparison: { greater_than: Date.today }
  validates :end_date, comparison: { greater_than: :start_date }, presence: true
  validates :user_id, presence: true
  validates :comment, presence: true, length: { maximum: 500 }

  enum status: {
    hold: 0,
    accepted: 1,
    finished: 2,
    canceled: 3
  }

  def mailer_update(old_start_date, old_end_date, new_start_date, new_end_date, template_uuid)
    I18n.locale = :fr
    self.admin_comment.nil? ? message = "" : message = self.admin_comment
    mail = Mailtrap::Mail::FromTemplate.new(
      from: { email: 'from@demomailtrap.com', name: 'Valou Coiffure' },
      to: [
        { email: 'gagnaire.flo@gmail.com' }
      ],
      template_uuid: template_uuid,
      template_variables: {
        firstname: self.user.firstname,
        lastname: self.user.lastname,
        link: "http://localhost/dashboard/#{user_id}",
        message: message,
        old_start_date: I18n.l(old_start_date, format: :custom),
        old_end_date: I18n.l(old_end_date, format: :custom),
        new_start_date: I18n.l(new_start_date, format: :custom),
        new_end_date: I18n.l(new_end_date, format: :custom)

      }
    )
    client = Mailtrap::Client.new()
    client.send(mail)
  end

  private

  def mailer_admin
    I18n.locale = :fr
    case self.status
      when "hold" then template_uuid = "7532b4fe-6346-41cc-9edb-e5f7ec75fa29"
      when "accepted" then template_uuid = "d986b954-3dc0-4f18-a3ba-4ea15f5a7778"
      when "finished" then template_uuid = "bb50996b-7744-4087-8657-345a8f8aa0d9"
      when "canceled" then template_uuid = "c6585d13-3c1f-44e5-bc76-665db9068772"
    end
    mail = Mailtrap::Mail::FromTemplate.new(
      from: { email: 'from@demomailtrap.com', name: 'Valou Coiffure' },
      to: [
        { email: 'gagnaire.flo@gmail.com' }
      ],
      template_uuid: template_uuid,
      template_variables: {
        firstname: 'Valou',
        lastname: 'CDB',
        start_date: I18n.l(self.start_date, format: :custom),
        end_date: I18n.l(self.end_date, format: :custom),
        created_at: I18n.l(self.created_at, format: :custom),
        link: "http://localhost/reservation/#{self.id}",
        user: "#{self.user.firstname.capitalize} #{self.user.lastname.capitalize}"
      }
    )
    client = Mailtrap::Client.new()
    client.send(mail)
  end

  def mailer_user
    I18n.locale = :fr
    self.admin_comment.nil? ? message = "" : message = self.admin_comment
    if self.status.nil?
      @template_uuid = "3e4c9e12-c352-491a-a6ee-5f967263b92c"
      self.update(status: 0)
    end
    case self.status
      when "accepted" then @template_uuid = "49d126b2-d0a7-45a5-a237-ebc66a1cf503"
      when "finished" then @template_uuid = "363b50b7-0689-4e53-872f-04df9ffb2063"
      when "canceled" then @template_uuid = "0de9b64b-4d35-4a60-b9a9-b3b508d34e60"
    end
    if @template_uuid.nil?
      return
    end
    mail = Mailtrap::Mail::FromTemplate.new(
      from: { email: 'from@demomailtrap.com', name: 'Valou Coiffure' },
      to: [
        { email: 'gagnaire.flo@gmail.com' }
      ],
      template_uuid: @template_uuid,
      template_variables: {
        firstname: self.user.firstname,
        lastname: self.user.lastname,
        start_date: I18n.l(self.start_date, format: :custom),
        end_date: I18n.l(self.end_date, format: :custom),
        created_at: I18n.l(self.created_at, format: :custom),
        link: "http://localhost/dashboard/#{user_id}",
        message: message,
      }
    )
    client = Mailtrap::Client.new()
    client.send(mail)
  end



  def create_availability
    Availability.create!(start_date: self.start_date, end_date: self.end_date, available: false) if self.status == "accepted"
  end
end
