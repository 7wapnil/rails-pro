class ApplicationWorker
  include Sidekiq::Worker
  sidekiq_options failures: :exhausted, retry: 3

  def perform(enqueued_at)
    setup_logger

    @start_time = Time.now.to_f
    @enqueued_at = enqueued_at
  end

  protected

  def setup_logger
    Rails.logger = ::Sidekiq.logger if jid
  end

  def log_success
    msg = "#{self.class.name} successfully finished a job"
    log_process(:info, msg)
  end

  def log_failure(error)
    log_process(:error, error.message)
  end

  # rubocop:disable Metrics/MethodLength
  def log_process(level, message)
    current_time = Time.now.to_f
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
  # rubocop:enable Metrics/MethodLength
end
