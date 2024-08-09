# frozen_string_literal: true

url = ENV['REDIS_URL']

if url
  Sidekiq.configure_server do |config|
    config.redis = { url: }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: }
  end
end
