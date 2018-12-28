class ApplicationWorker
  include Sidekiq::Worker
  include JobLogger
  include JobLogger::ThreadInitializer

  sidekiq_options failures: :exhausted, retry: 3
end
