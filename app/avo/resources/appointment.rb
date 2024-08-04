class Avo::Resources::Appointment < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :idlo
    field :start_date, as: :date_time
    field :end_date, as: :date_time
    field :comment, as: :textarea
    field :status, as: :select, enum: ::Appointment.statuses
    field :seller_comment, as: :textarea
    field :price, as: :number
    field :seller_id, as: :number
    field :customer_id, as: :number
    field :customer, as: :belongs_to
    field :seller, as: :belongs_to
    field :appointment_services, as: :has_many
    field :services, as: :has_many, through: :appointment_services
  end
end
