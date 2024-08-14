class ApiKey < ApplicationRecord
  belongs_to :admin
  has_secure_token :api_key
  before_create :init_api_key


  def init_api_key
    self.api_key = SecureRandom.uuid_v7
  end

  def update_api_key
    self.update(api_key: SecureRandom.uuid_v7)
  end
end
