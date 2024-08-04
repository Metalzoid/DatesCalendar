class Avo::Resources::Availability < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :idlo
    field :start_date, as: :date_time
    field :end_date, as: :date_time
    field :available, as: :boolean
    field :user_id, as: :number
    field :user, as: :belongs_to
  end
end
