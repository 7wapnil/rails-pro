module Radar
  class MarketGeneratorWorker < ApplicationWorker
    def perform(event_id, market_data)
      Rails.logger.debug "Generating market for event #{event_id}"
      OddsFeed::Radar::MarketGenerator::Service.call(event_id, market_data)
    end
  end
end
