class EventProcessingWorker
  include Sidekiq::Worker

  def perform(payload)
    Rails.logger.debug "Received job: #{payload}"
    OddsFeed::Service.call(OddsFeed::Radar::Client.new, payload)
  end
end
