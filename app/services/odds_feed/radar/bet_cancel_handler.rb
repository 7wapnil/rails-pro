module OddsFeed
  module Radar
    class BetCancelHandler < RadarMessageHandler
      attr_accessor :batch_size

      def initialize(payload)
        super(payload)
        @batch_size = 20
      end

      def handle
        validate_message
        query = build_query
        query.update_all(status: Bet.statuses[:cancelled])

        query.find_in_batches(batch_size: @batch_size) do |batch|
          emit_websocket_signals(batch)
        end
      end

      private

      def input_data
        @payload['bet_cancel']
      end

      def validate_message
        no_range = input_data['start_time'].nil? && input_data['end_time'].nil?
        raise OddsFeed::InvalidMessageError if no_range
      end

      def build_query
        Bet
          .joins(odd: [{ market: :event }])
          .where(events: { external_id: input_data['event_id'] })
          .merge(bets_with_start_time)
          .merge(bets_with_end_time)
      end

      def bets_with_start_time
        return {} if input_data['start_time'].nil?
        Bet.where('bets.created_at >= ?',
                  to_datetime(input_data['start_time']))
      end

      def bets_with_end_time
        return {} if input_data['end_time'].nil?
        Bet.where('bets.created_at < ?',
                  to_datetime(input_data['end_time']))
      end

      def to_datetime(timestamp)
        Time
          .at(timestamp.to_i)
          .to_datetime
          .in_time_zone
      end

      def emit_websocket_signals(batch)
        batch.each do |bet|
          WebSocket::Client.instance.emit(WebSocket::Signals::BET_CANCELLED,
                                          id: bet.id,
                                          customerId: bet.customer_id)
        end
      end
    end
  end
end
