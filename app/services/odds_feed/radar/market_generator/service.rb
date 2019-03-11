# frozen_string_literal: true

module OddsFeed
  module Radar
    module MarketGenerator
      class Service < ::ApplicationService
        include JobLogger

        def initialize(event, markets_data, cache = {})
          @event = event
          @markets_data = markets_data
          @markets = []
          @odds = []
          @cache = cache
        end

        def call
          build
          import
          emit_events
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
          market_template =
            market_template_find_by!(external_id: market_data['id'])
          data_object = MarketData.new(@event, market_data, market_template)
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

        def market_template_find_by!(external_id:)
          market_template_from_cache(external_id) ||
            MarketTemplate.find_by!(external_id: external_id)
        rescue ActiveRecord::RecordNotFound
          raise(
            ActiveRecord::RecordNotFound,
            "MarketTemplate with external id #{external_id} not found."
          )
        end

        def market_template_from_cache(external_id)
          return nil unless @cache && @cache[:market_templates_cache]

          @cache[:market_templates_cache][external_id.to_i]
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
          @odds.push(*OddsGenerator.call(market, data_object))
        end

        def import
          import_markets
          import_odds
        end

        def import_markets
          Market.import(@markets,
                        validate: false,
                        on_duplicate_key_update: {
                          conflict_target: %i[external_id],
                          columns: %i[status priority]
                        })
        end

        def import_odds
          Odd.import(@odds,
                     validate: false,
                     on_duplicate_key_update: {
                       conflict_target: %i[external_id],
                       columns: %i[status value]
                     })
        end

        def emit_events
          emit_markets_update
        end

        def emit_markets_update
          @markets.map do |market|
            WebSocket::Client.instance.trigger_market_update(market)
          end
        end
      end
    end
  end
end
