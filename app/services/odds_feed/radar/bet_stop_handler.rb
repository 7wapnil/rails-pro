module OddsFeed
  module Radar
    class BetStopHandler < RadarMessageHandler
      attr_accessor :batch_size

      def initialize(payload)
        super(payload)
        @batch_size = 20
      end

      def handle
        query = build_query
        query.update_all(status: stop_status)

        query.find_in_batches(batch_size: @batch_size) do |batch|
          emit_websocket_signals(batch)
        end
      end

      private

      def input_data
        @payload['bet_stop']
      end

      def build_query
        Market
          .joins(:event)
          .where(events: { external_id: input_data['event_id'] })
      end

      def stop_status
        is_suspended = input_data['market_status'].nil? ||
                       input_data['market_status'] == 'suspended'

        return Market.statuses[:suspended] if is_suspended
        Market.statuses[:inactive]
      end

      def emit_websocket_signals(batch)
        batch.each do |market|
          WebSocket::Client.instance.emit(WebSocket::Signals::UPDATE_MARKET,
                                          id: market.id,
                                          eventId: market.event.id,
                                          status: market.status)
        end
      end
    end
  end
end
