# frozen_string_literal: true

module Sidekiq
  module PatchedProcessor
    def execute_job(worker, cloned_args)
      worker.populate_job_info_to_thread
      worker.perform(*cloned_args)
    rescue StandardError => e
      worker.log_job_failure(e) if log_job_failure?(worker)
      raise(e)
    end

    private

    def log_job_failure?(worker)
      worker.is_a?(::ApplicationWorker) && !worker.is_a?(::Radar::BaseUofWorker)
    end
  end
end
