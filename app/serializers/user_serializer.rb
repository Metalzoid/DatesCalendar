# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :firstname, :lastname, :company, :role, :phone_number

end
