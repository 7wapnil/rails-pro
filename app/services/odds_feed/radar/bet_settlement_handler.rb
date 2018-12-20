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

      def invalid_bet_ids
        @invalid_bet_ids ||= []
      end

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
        revalidate_suspended_bets(bets)
        settle_bets(bets, outcome)

        bets = get_settled_bets(external_id)
        logger_level = bets.size.positive? ? :info : :debug
        log_job_message(logger_level, "#{bets.size} bets settled")

        bets
          .find_in_batches { |batch| emit_websocket_settlement_signals(batch) }
      end

      def revalidate_suspended_bets(bets)
        bets.suspended.each { |bet| revalidate_suspended_bet(bet) }
      end

      def revalidate_suspended_bet(bet)
        bet.send_to_internal_validation!
      rescue AASM::InvalidTransition, ActiveRecord::Error => error
        log_job_failure(error)
      rescue ActiveRecord::Error
        log_job_failure("Bet ##{bet.id} can't be set as `suspended`")
      end

      def settle_bets(bets, outcome)
        bets.unsuspended.each { |bet| settle_bet(bet, outcome) }
      end

      def settle_bet(bet, outcome)
        bet.settle!(
          settlement_status: outcome['result'] == '1' ? :won : :lost,
          void_factor: outcome['void_factor']
        )
      rescue StandardError => error
        invalid_bet_ids.push(bet.id)

        log_job_failure("Bet ##{bet.id} can't be settled")
        log_job_failure(error)
      end

      def process_bets(external_id)
        get_settled_bets(external_id)
          .each { |bet| BetSettelement::Service.call(bet) }
      end

      def bets_by_external_id(external_id)
        Bet
          .joins(:odd)
          .where(odds: { external_id: external_id })
      end

      def get_settled_bets(external_id)
        bets_by_external_id(external_id)
          .unsuspended
          .where.not(id: invalid_bet_ids)
      end

      def emit_websocket_settlement_signals(batch)
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
