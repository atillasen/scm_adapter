# frozen_string_literal: true

module ScmAdapter
  module JobRunner
    module_function

    def run(job_class, **args)
      sidekiq_enabled? ? job_class.perform_later(**args) : job_class.perform_now(**args)
    end

    def sidekiq_enabled?
      settings = Setting.plugin_scm_adapter.to_h
      settings["sidekiq_enabled"] == true || settings["sidekiq_enabled"].to_s == "1"
    rescue StandardError => e
      Rails.logger.warn("[scm_adapter] sidekiq_enabled read failed: #{e.class}: #{e.message}") if defined?(Rails)
      false
    end
  end
end
