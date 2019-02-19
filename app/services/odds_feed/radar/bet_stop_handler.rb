module OddsFeed
  module Radar
    class BetStopHandler < RadarMessageHandler
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
            events: { external_id: input_data['event_id'] }
          )
      end

      def stop_status
        is_suspended = input_data['market_status'].nil? ||
                       input_data['market_status'] == 'suspended'

        return Market::SUSPENDED if is_suspended

        Market::INACTIVE
      end

      def update_markets(batch)
        batch.each do |market|
          market.status = stop_status
          market.save!
        rescue ActiveRecord::RecordInvalid => e
          log_job_failure(e)
        end
      end

      def event
        @event ||= Event.find_by(external_id: input_data['event_id'])
      end

      def emit_websocket
        unless event
          return log_job_message(
            :warn,
            message: 'Event not found',
            event_id: input_data['event_id']
          )
        end

        WebSocket::Client.instance.trigger_event_update(event)
      end
    end
  end
end
