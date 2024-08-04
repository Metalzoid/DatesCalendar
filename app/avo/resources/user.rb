class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :idlo
    field :email, as: :text
    field :confirmation_token, as: :text
    field :confirmed_at, as: :date_time
    field :confirmation_sent_at, as: :date_time
    field :unconfirmed_email, as: :text
    field :failed_attempts, as: :number
    field :unlock_token, as: :text
    field :locked_at, as: :date_time
    field :jti, as: :text
    field :company, as: :text
    field :firstname, as: :text
    field :lastname, as: :text
    field :role, as: :select, enum: ::User.roles
    field :apointments, as: :has_many
    field :services, as: :has_many
    field :availability, as: :has_many
  end
end
