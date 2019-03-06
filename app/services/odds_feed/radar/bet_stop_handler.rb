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

      def build_query
        Market
          .joins(:event)
          .where(
            status: Market::ACTIVE,
            events: { external_id: event_id }
          )
      end

      def stop_status
        market_status = MarketStatus.new(input_data['market_status'])

        return Market::SUSPENDED if market_status.empty?

        market_status.market_status
      end

      def update_markets(batch)
        batch.each do |market|
          market.status = stop_status
          market.save!
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
