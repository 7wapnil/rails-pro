module OddsFeed
  module Radar
    class BetStopHandler < RadarMessageHandler
      include WebsocketEventEmittable

      attr_accessor :batch_size

      def initialize(payload, profiler_dump)
        super(payload, profiler_dump)
        @batch_size = 20
      end

      def handle
        update_markets
        emit_websocket
      end

      private

      def update_markets
        target_status = MarketStatus.stop_status(market_status_code)

        markets = markets_to_be_changed_query
                  .find_each(batch_size: @batch_size).to_a
        markets_to_be_changed_query.update_all(status: target_status)
        markets.each do |market|
          market.status = target_status
          emit_market_update(market)
        rescue ActiveRecord::RecordInvalid => e
          log_job_failure(e)
        end
      end

      def input_data
        @payload['bet_stop']
      end

      def market_status_code
        input_data['market_status']
      end

      def markets_to_be_changed_query
        Market
          .joins(:event)
          .where(
            status: Market::ACTIVE,
            events: { external_id: event_id }
          )
      end

      def emit_market_update(market)
        WebSocket::Client.instance.trigger_market_update(market)
      end
    end
  end
end
