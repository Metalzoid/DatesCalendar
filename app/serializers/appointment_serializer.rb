class AppointmentSerializer
  include JSONAPI::Serializer
  attributes :id, :start_date, :end_date, :status, :comment, :seller_comment, :price, :seller_id, :customer_id
end
