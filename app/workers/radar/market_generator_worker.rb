module Radar
  class MarketGeneratorWorker < ApplicationWorker
    def perform(event_id, market_data)
      event = event(event_id)
      Rails.logger.debug "Generating market for event #{event.external_id}"
      OddsFeed::Radar::MarketGenerator.new(event, market_data).generate
    end

    private

    def event(id)
      Event.find(id)
    end
  end
end
