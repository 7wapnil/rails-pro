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
            external_id = generator.generate

            update_bets(external_id, outcome)
            process_bets(external_id)
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

      def update_bets(external_id, outcome)
        log_job_message(
          :debug, "Settling bets for odd with EID #{external_id}"
        )

        bets = bets_by_external_id(external_id)

        bets.each do |bet|
          bet.settle!(
            settlement_status: outcome['result'] == '1' ? :won : :lost,
            void_factor: outcome['void_factor']
          )
        end
        logger_level = bets.count.positive? ? :info : :debug
        log_job_message(logger_level, "#{bets.count} bets settled")

        bets.find_in_batches { |batch| emit_websocket_signals(batch) }
      end

      def process_bets(external_id)
        bets = bets_by_external_id(external_id)
        bets.each do |bet|
          BetSettelement::Service.call(bet)
        end
      end

      def bets_by_external_id(external_id)
        Bet
          .joins(:odd)
          .where(odds: { external_id: external_id })
      end

      def emit_websocket_signals(batch)
        batch.each do |bet|
          WebSocket::Client.instance.emit(WebSocket::Signals::BET_SETTLED,
                                          id: bet.id,
                                          customerId: bet.customer_id,
                                          result: bet.won?,
                                          voidFactor: bet.void_factor)
        end
      end
    end
  end
end
