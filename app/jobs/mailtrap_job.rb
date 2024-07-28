class MailtrapJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    I18n.locale = :fr
    template_uuid = params[:template_uuid]
    return if template_uuid.nil?
    
    mail = build_mail(params, template_uuid)
    send_mail(mail)
  end

  private

  def build_mail(params, template_uuid)
    Mailtrap::Mail::FromTemplate.new(
      from: { email: 'from@demomailtrap.com', name: 'Valou Coiffure' },
      to: [{ email: params[:to_email] }],
      template_uuid: template_uuid,
      template_variables: params[:template_variables]
    )
  end

  def send_mail(mail)
    client = Mailtrap::Client.new
    client.send(mail)
  end
end
