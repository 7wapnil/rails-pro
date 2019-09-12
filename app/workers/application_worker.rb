class ApplicationWorker
  include Sidekiq::Worker
  include JobLogger
  include JobLogger::ThreadInitializer

  sidekiq_options failures: :exhausted, retry: 3

  def execute_logged(enqueued_at:)
    raise 'Logged execution requires block' unless block_given?

    @enqueued_at = enqueued_at
    populate_enqueued_at_to_thread

    yield

    log_success
  rescue StandardError => e
    # NB: Main job logging for errors is disabled here:
    # `lib/sidekiq/patched_processor.rb:9`
    log_failure e
    raise e
  end
end
