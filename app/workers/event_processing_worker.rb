class EventProcessingWorker
  include Sidekiq::Worker

  def perform(payload)
    return payload
  end
end
