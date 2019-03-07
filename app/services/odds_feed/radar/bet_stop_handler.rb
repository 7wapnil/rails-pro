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
        build_query.find_in_batches(batch_size: @batch_size) do |batch|
          update_markets(batch)
        end

        emit_websocket
      end

      private

      def input_data
        @payload['bet_stop']
      end

      def market_status_code
        input_data['market_status']
      end

      def build_query
        Market
          .joins(:event)
          .where(
            status: Market::ACTIVE,
            events: { external_id: event_id }
          )
      end

      def update_markets(batch)
        batch.each do |market|
          market.update(status: MarketStatus.stop_status(market_status_code))
          emit_market_update(market)
        rescue ActiveRecord::RecordInvalid => e
          log_job_failure(e)
        end
      end

      def emit_market_update(market)
        WebSocket::Client.instance.trigger_market_update(market)
      end
    end
  end
end
