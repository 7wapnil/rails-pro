module OddsFeed
  module Radar
    module MarketGenerator
      class Service < ::ApplicationService
        def logger
          Rails.logger
        end

        def initialize(event_id, markets_data)
          @event = Event.find(event_id)
          @markets_data = markets_data
          @markets = []
          @market_data_objects = []
        end

        def call
          generate_markets
          generate_odds
        end

        private

        def generate_markets
          build_markets
          Market.import([:name, :status, :event_id, :external_id],
                        @markets,
                        validate: true,
                        on_duplicate_key_update: { conflict_target: [:external_id],
                                                   columns: [:status] })
        end

        def build_markets
          @markets_data.each do |market_data|
            market_data_object = MarketData.new(@event, market_data)
            @market_data_objects << market_data_object
            @markets << Market.new(external_id: market_data_object.external_id,
                                  event_id: @event.id,
                                  name: market_data_object.name,
                                  status: market_data_object.status)
          end
        end

        def generate_odds
          @market_data_objects.each do |market_data|
            OddsGenerator.call(market_data)
          end
        end
      end
    end
  end
end
