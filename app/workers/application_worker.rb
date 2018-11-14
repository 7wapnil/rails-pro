class ApplicationWorker
  include Sidekiq::Worker
  sidekiq_options failures: :exhausted, retry: 3
end
