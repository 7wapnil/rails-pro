class ApplicationWorker
  include Sidekiq::Worker
  include JobLogger
  include JobLogger::Initializer

  sidekiq_options failures: :exhausted, retry: 3

  def perform(enqueued_at = nil)
    @enqueued_at = enqueued_at

    populate_job_info_to_thread
  end
end
