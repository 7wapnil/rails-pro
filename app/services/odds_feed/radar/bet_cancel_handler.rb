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
        query.update_all(status: StateMachines::BetStateMachine::CANCELLED)

        query.find_in_batches(batch_size: @batch_size) do |batch|
          emit_websocket_signals(batch)
        end
      end

      private

      def input_data
        @payload['bet_cancel']
      end

      def event_id
        input_data['event_id']
      end

      def markets
        Array.wrap(input_data['market'])
      end

      def validate_message
        invalid = event_id.nil? || markets.empty?
        raise OddsFeed::InvalidMessageError, @payload if invalid
      end

      def build_query
        Bet
          .joins(odd: :market)
          .where(markets: { external_id: market_external_ids })
          .merge(bets_with_start_time)
          .merge(bets_with_end_time)
      end

      def market_external_ids
        markets.map do |market|
          OddsFeed::Radar::ExternalId
            .new(event_id: event_id,
                 market_id: market['id'],
                 specs: market['specifiers'].to_s)
            .generate
        end
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
