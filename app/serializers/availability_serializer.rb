class AvailabilitySerializer
  include JSONAPI::Serializer
  attributes :id, :start_date, :end_date, :available, :user_id
end
