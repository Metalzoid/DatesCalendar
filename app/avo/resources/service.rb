class Avo::Resources::Service < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :idlo
    field :title, as: :text
    field :price, as: :number
    field :user_id, as: :number
    field :time, as: :number
    field :user, as: :belongs_to
    field :appointment_services, as: :has_many
    field :appointments, as: :has_many, through: :appointment_services
  end
end
