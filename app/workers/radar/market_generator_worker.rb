module Radar
  class MarketGeneratorWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def perform(event_id, market_data)
      Rails.logger.debug "Generating market for event #{event_id}"
      OddsFeed::Radar::MarketGenerator::Service.call(event_id, market_data)
    end
  end
end
