module OddsFeed
  module Radar
    class BetSettlementHandler < RadarMessageHandler
      def handle
        validate_message

        markets.each do |market|
          market['outcome'].each do |outcome|
            generator = ExternalId.new(event_id: input_data['event_id'],
                                       market_id: market['id'],
                                       specs: market['specs'],
                                       outcome_id: outcome['id'])

            update_odd(generator.generate, outcome)
          end
        end
      end

      private

      def validate_message
        is_invalid = input_data['outcomes'].nil? ||
                     input_data['outcomes']['market'].nil?
        raise OddsFeed::InvalidMessageError if is_invalid
      end

      def input_data
        @payload['bet_settlement']
      end

      def markets
        Array.wrap(input_data['outcomes']['market'])
      end

      def update_odd(external_id, outcome)
        Rails.logger.info "Settling bets for odd with EID #{external_id}"

        query = build_query(external_id)
        query.update_all(status: Bet.statuses[:settled],
                         result: outcome['result'] == '1',
                         void_factor: outcome['void_factor'])
        Rails.logger.info "#{query.count} bets settled"

        query.find_in_batches { |batch| emit_websocket_signals(batch) }
      end

      def build_query(external_id)
        Bet
          .joins(:odd)
          .where(odds: { external_id: external_id })
      end

      def emit_websocket_signals(batch)
        batch.each do |bet|
          WebSocket::Client.instance.emit(WebSocket::Signals::BET_SETTLED,
                                          id: bet.id,
                                          customerId: bet.customer_id,
                                          result: bet.result,
                                          voidFactor: bet.void_factor)
        end
      end
    end
  end
end
