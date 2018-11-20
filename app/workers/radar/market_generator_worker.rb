module Radar
  class MarketGeneratorWorker < ApplicationWorker
    def perform(event_id, market_data, timestamp)
      Rails.logger.debug "Generating market for event #{event_id}"
      OddsFeed::Radar::MarketGenerator::Service.call(event_id, market_data, timestamp)
    end
  end
end
