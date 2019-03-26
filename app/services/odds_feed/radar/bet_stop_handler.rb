module OddsFeed
  module Radar
    class BetStopHandler < RadarMessageHandler
      include WebsocketEventEmittable

      attr_accessor :batch_size

      def initialize(payload)
        super(payload)
        @batch_size = 20
      end

      def handle
        update_markets
        emit_websocket
      end

      private

      def update_markets
        target_status = MarketStatus.stop_status(market_status_code)

        markets_to_be_changed_query.update_all(status: target_status)

        emit_event_bet_stop(event, target_status)
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

      def emit_event_bet_stop(event)
        WebSocket::Client.instance.trigger_event_bet_stop(event)
      end
    end
  end
end
