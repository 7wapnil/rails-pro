module OddsFeed
  module Radar
    module MarketGenerator
      class Service < ::ApplicationService
        include JobLogger

        def initialize(event_id, markets_data)
          @event = Event.find(event_id)
          @markets_data = markets_data
          @markets = []
          @odds = []
        end

        def call
          build
          import
        end

        private

        def build
          @markets_data.each do |market_data|
            build_market(market_data)
          rescue StandardError => e
            log_job_message(:debug, { message: e.message,
                                      market_data: market_data }.to_json)
            next
          end
        end

        def build_market(market_data)
          data_object = MarketData.new(@event, market_data)
          market = build_market_model(data_object)
          return unless valid?(market)

          @markets << market
          build_odds(market, data_object)
        end

        def build_market_model(data_object)
          Market.new(external_id: data_object.external_id,
                     event_id: @event.id,
                     name: data_object.name,
                     status: data_object.status,
                     category: data_object.category)
        end

        def valid?(market)
          return true if market.valid?

          msg = <<-MESSAGE
            Market '#{market.external_id}' is invalid: \
            #{market.errors.full_messages.join("\n")}
          MESSAGE
          log_job_message(:warn, msg.squish)
          false
        end

        def build_odds(market, data_object)
          OddsGenerator.call(market, data_object).each do |odd|
            @odds << odd
          end
        end

        def import
          import_markets
          import_odds
          emit_events
        end

        def import_markets
          Market.import(@markets,
                        validate: false,
                        on_duplicate_key_update: {
                          conflict_target: [:external_id],
                          columns: %i[status priority]
                        })
        end

        def import_odds
          Odd.import(@odds,
                     validate: false,
                     on_duplicate_key_update: {
                       conflict_target: [:external_id],
                       columns: %i[status value]
                     })
        end

        def emit_events
          emit_markets_update
          emit_odds_update
        end

        def emit_markets_update
          data = @markets.map do |market|
            { id: market.id.to_s,
              status: market.status,
              priority: market.priority }
          end
          WebSocket::Client.instance.emit(WebSocket::Signals::MARKETS_UPDATED,
                                          id: @event.id.to_s,
                                          data: data)
        end

        def emit_odds_update
          data = @odds.map do |odd|
            { id: odd.id.to_s,
              marketId: odd.market.id.to_s,
              status: odd.status,
              value: odd.value }
          end
          WebSocket::Client.instance.emit(WebSocket::Signals::ODDS_UPDATED,
                                          id: @event.id.to_s,
                                          data: data)
        end
      end
    end
  end
end
