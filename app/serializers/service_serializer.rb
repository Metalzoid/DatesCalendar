class ServiceSerializer
  include JSONAPI::Serializer
  attributes :id, :title, :price, :time, :user_id, :disabled
end
