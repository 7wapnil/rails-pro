module OddsFeed
  module Radar
    class BetSettlementHandler < RadarMessageHandler
      def initialize(payload)
        super(payload)
        @market_external_ids = []
      end

      def handle
        validate_message
        store_market_ids
        process_outcomes
        update_markets
      end

      private

      def validate_message
        is_invalid = input_data['outcomes'].nil? ||
                     input_data['outcomes']['market'].nil?
        raise OddsFeed::InvalidMessageError if is_invalid
      end

      def store_market_ids
        markets.each { |payload| store_market_id(payload) }
      end

      def process_outcomes
        markets.each do |market_data|
          market_data['outcome'].each do |outcome|
            generator = ExternalId.new(event_id: input_data['event_id'],
                                       market_id: market_data['id'],
                                       specs: market_data['specifiers'],
                                       outcome_id: outcome['id'])
            external_id = generator.generate

            update_bets(external_id, outcome)
            process_bets(external_id)
          end
        end
      end

      def store_market_id(market_data)
        generator = ExternalId.new(event_id: input_data['event_id'],
                                   market_id: market_data['id'],
                                   specs: market_data['specifiers'])
        @market_external_ids << generator.generate
      end

      def update_markets
        Market
          .where(external_id: @market_external_ids)
          .update_all(status: Market::SETTLED)
      end

      def invalid_bet_ids
        @invalid_bet_ids ||= []
      end

      def input_data
        @payload['bet_settlement']
      end

      def markets
        @markets ||= Array.wrap(input_data['outcomes']['market'])
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
    end
  end
end
