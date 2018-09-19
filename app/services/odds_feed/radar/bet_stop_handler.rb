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

      def update_markets(batch)
        batch.each do |market|
          market.status = stop_status
          market.save!
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error e
        end
      end
    end
  end
end
