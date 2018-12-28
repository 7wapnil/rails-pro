# frozen_string_literal: true

module Sidekiq
  module PatchedProcessor
    def execute_job(worker, cloned_args)
      worker.populate_job_info_to_thread
      worker.perform(*cloned_args)
    rescue StandardError => e
      worker.log_job_failure(e) unless worker.is_a?(::Radar::BaseUofWorker)
      raise(e)
    end
  end
end
