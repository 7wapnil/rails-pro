module Radar
  class EventProcessingWorker
    include Sidekiq::Worker

    def perform(payload)
      Rails.logger.debug "Received job: #{payload}"
      OddsFeed::Radar::OddsChangeHandler.new(payload)
    end
  end
end
