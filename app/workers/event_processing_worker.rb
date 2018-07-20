class EventProcessingWorker
  include Sidekiq::Worker

  def perform(payload)
    payload
  end
end
