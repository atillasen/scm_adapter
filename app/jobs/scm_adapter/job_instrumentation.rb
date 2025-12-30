# frozen_string_literal: true

require "active_support/concern"
require "scm_adapter/instrumentation"

module ScmAdapter
  module JobInstrumentation
    extend ActiveSupport::Concern

    included do
      around_perform :record_job_metrics
    end

    private

    def record_job_metrics(&block)
      ScmAdapter::Instrumentation.measure(
        event: "job",
        tags: {
          job: self.class.name,
          queue: self.class.queue_name
        }
      ) { block.call }
    end
  end
end
