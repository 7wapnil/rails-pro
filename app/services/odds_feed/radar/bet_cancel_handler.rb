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
        update_markets_status

        query = build_query
        query.update_all(status: StateMachines::BetStateMachine::CANCELLED)

        emit_websocket
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

      def update_markets_status
        Market
          .where(external_id: market_external_ids)
          .update_all(status: Market::CANCELLED)
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

      def event
        @event ||= Event.find_by(external_id: event_id)
      end

      def emit_websocket
        unless event
          return log_job_message(
            :warn,
            message: 'Event not found',
            event_id: event_id
          )
        end

        WebSocket::Client.instance.trigger_event_update(event)
      end
    end
  end
end
