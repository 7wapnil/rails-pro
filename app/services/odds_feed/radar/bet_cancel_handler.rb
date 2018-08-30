module OddsFeed
  module Radar
    class BetCancelHandler < RadarMessageHandler
      def handle
        validate_message
        query = build_query
        query.update_all(status: Bet.statuses[:cancelled])
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
    end
  end
end
