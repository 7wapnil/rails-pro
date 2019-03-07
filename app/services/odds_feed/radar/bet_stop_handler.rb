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
        market_ids = build_query.pluck(:id)
        build_query
          .update_all(status: MarketStatus.stop_status(market_status_code))
        Market.where(id: market_ids).find_in_batches(batch_size: @batch_size) do |batch|
          batch.each do |market|
            emit_market_update(market)
          rescue ActiveRecord::RecordInvalid => e
            log_job_failure(e)
          end
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

      def emit_market_update(market)
        WebSocket::Client.instance.trigger_market_update(market)
      end
    end
  end
end
