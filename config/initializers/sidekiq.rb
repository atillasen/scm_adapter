# frozen_string_literal: true
require "sidekiq"

redis_url = ENV.fetch("REDIS_URL", "redis://redis:6379/0")
queues = ENV.fetch("SCM_ADAPTER_SIDEKIQ_QUEUES", nil)
queues = queues.to_s.split(",").map(&:strip).reject(&:empty?)
queues = %w[webhooks comment_back mirror default] if queues.empty?

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
  config.options[:queues] = queues
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
