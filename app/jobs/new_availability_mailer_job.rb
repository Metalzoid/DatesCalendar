class NewAvailabilityMailerJob < ApplicationJob
  queue_as :default

  def perform(availability)
    I18n.locale = :fr
    mail = Mailtrap::Mail::FromTemplate.new(
      from: { email: 'from@demomailtrap.com', name: 'Valou Coiffure' },
      to: [{ email: availability.user.email }],
      template_uuid: 'd2f2779b-3b07-4770-85a1-f86a06d8e62b',
      template_variables: {
        firstname: availability.user.firstname,
        lastname: availability.user.lastname,
        start_date: I18n.l(availability.start_date, format: :custom),
        end_date: I18n.l(availability.end_date, format: :custom),
        created_at: I18n.l(availability.created_at, format: :custom)
      }
    )
    client = Mailtrap::Client.new
    client.send(mail)
  end
end
