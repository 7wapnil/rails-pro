class ApplicationWorker
  include Sidekiq::Worker
  sidekiq_options failures: :exhausted
end
