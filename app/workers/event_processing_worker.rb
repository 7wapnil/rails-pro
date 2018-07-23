class EventProcessingWorker
  include Sidekiq::Worker

  def perform(payload)
    Rails.logger.debug "Received job: #{payload}"
    OddsFeed::Service.call(OddsFeed::Radar::Client.new, payload)
  rescue => ex
    Rails.logger.error ex.message
  end
end
