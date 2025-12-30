# frozen_string_literal: true

require "logger"

module ScmAdapter
  module Instrumentation
    module_function

    def measure(event:, tags: {})
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
    rescue => e
      emit(event: event, status: :error, duration_ms: duration_ms(start), tags: tags, error: e)
      raise
    else
      emit(event: event, status: :ok, duration_ms: duration_ms(start), tags: tags)
    end

    def emit(event:, status:, duration_ms:, tags: {}, error: nil)
      payload = tags.compact.merge(status: status, duration_ms: duration_ms)
      if error
        payload[:error_class] = error.class.name
        payload[:error_message] = error.message
      end

      ActiveSupport::Notifications.instrument("scm_adapter.#{event}", payload)
    rescue StandardError
      # Notifications sollten nie Ausnahmen werfen
    ensure
      log_line = "[scm_adapter][#{event}] status=#{status} duration_ms=#{duration_ms}"
      log_line << " tags=#{payload.except(:status, :duration_ms)}" if payload.any?
      log_line << " error=#{error.class}: #{error.message}" if error
      logger.public_send(status == :ok ? :info : :error, log_line)
    end

    def duration_ms(start)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(1)
    end

    def logger
      return Rails.logger if defined?(Rails)
      @logger ||= Logger.new($stdout).tap { |l| l.level = Logger::INFO }
    end
  end
end
