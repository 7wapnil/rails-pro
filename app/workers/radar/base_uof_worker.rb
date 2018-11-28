module Radar
  class BaseUofWorker < ApplicationWorker
    sidekiq_options retry: 3

    def perform(payload, enqueued_at)
      @enqueued_at = enqueued_at
      @start_time = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      execute(payload)
      log_success
    rescue StandardError => e
      log_failure e
      raise e
    end

    def worker_class
      raise ::NotImplementedError
    end

    private

    def execute(payload)
      worker_class.new(XmlParser.parse(payload)).handle
    end

    def log_success
      msg = "#{self.class.name} successfully finished a job"
      log_process(:info, msg)
    end

    def log_failure(error)
      log_process(:error, error.message)
    end

    def log_process(level, message)
      current_time = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      performing_time = @enqueued_at.zero? ? 0 : current_time - @enqueued_at
      execution_time = current_time - @start_time
      processing_time = performing_time + execution_time

      Rails.logger.send(
        level,
        jid: jid,
        worker: self.class.name,
        message: message,
        current_time: current_time,
        job_enqueued_at: @enqueued_at,
        job_performing_time: performing_time.round(3),
        job_execution_time: execution_time.round(3),
        overall_processing_time: processing_time.round(3)
      )
    end
  end
end
