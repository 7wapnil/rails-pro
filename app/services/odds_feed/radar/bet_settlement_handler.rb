# frozen_string_literal: true

module OddsFeed
  module Radar
    # rubocop:disable Metrics/ClassLength
    class BetSettlementHandler < RadarMessageHandler
      include WebsocketEventEmittable

      ACTIVE_VOID_FACTOR = '1'
      WIN_RESULT = '1'

      def initialize(payload)
        super(payload)
        @market_external_ids = []
      end

      def handle
        validate_message
        store_market_ids
        process_outcomes
        update_markets
        emit_websocket
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
        markets
          .reject { |market_data| skip_uncertain_settlement?(market_data) }
          .map { |market_data| process_outcomes_for(market_data) }
      end

      def store_market_id(market_data)
        generator = ExternalId.new(event_id: event_id,
                                   market_id: market_data['id'],
                                   specs: market_data['specifiers'])
        @market_external_ids << generator.generate
      end

      def update_markets
        Market
          .where(external_id: @market_external_ids)
          .each(&:settled!)
      end

      def invalid_bet_ids
        @invalid_bet_ids ||= []
      end

      def market_templates
        @market_templates ||=
          MarketTemplate
          .select(:id, :external_id, :payload)
          .where(external_id: markets.map { |m| m['id'] })
      end

      def market_template_for(external_id)
        market_templates.find do |market_template|
          market_template.external_id == external_id
        end
      end

      def skip_uncertain_settlement?(market_data)
        market_template = market_template_for(market_data['id'])

        market_template &&
          !market_template.payload['products'].include?('1') &&
          certainty_level < 2
      end

      def exit_with_uncertainty
        log_job_message(
          :info,
          message: I18n.t('errors.messages.odds_feed.low_certainty'),
          event_id: event_id,
          certainty_level: certainty_level
        )
      end

      def markets
        @markets ||= Array.wrap(input_data['outcomes']['market'])
      end

      def process_outcomes_for(market_data)
        Array.wrap(market_data['outcome']).each do |outcome|
          generator = ExternalId.new(event_id: event_id,
                                     market_id: market_data['id'],
                                     specs: market_data['specifiers'],
                                     outcome_id: outcome['id'])
          external_id = generator.generate

          update_bets(external_id, outcome)
          proceed_bets(external_id)
        end
      end

      def input_data
        @payload['bet_settlement']
      end

      def certainty_level
        input_data['certainty'].to_i
      end

      def update_bets(external_id, outcome)
        log_job_message(:debug, message: 'Settling bets for odd',
                                external_id: external_id)

        bets = bets_by_external_id(external_id)
        settle_bets(bets, outcome)

        bets = get_settled_bets(external_id)
        logger_level = bets.size.positive? ? :info : :debug
        log_job_message(logger_level, message: 'Bets settled',
                                      count: bets.size)
      end

      def settle_bets(bets, outcome)
        bets.each { |bet| settle_bet(bet, outcome) }
      end

      def settle_bet(bet, outcome)
        validate_void_factor!(outcome)

        bet.settle!(
          settlement_status: build_settlement_status(outcome),
          void_factor: outcome['void_factor']
        )
      rescue ::Bets::NotSupportedError => error
        bet.pending_manual_settlement!

        settlement_error!(bet, error)
      rescue StandardError => error
        settlement_error!(bet, error)
      end

      def validate_void_factor!(outcome)
        return if outcome['void_factor'].nil? || active_void_factor?(outcome)

        raise ::Bets::NotSupportedError,
              "Void factor: '#{outcome['void_factor']}' is not supported!"
      end

      def active_void_factor?(outcome)
        outcome['void_factor'].to_s == ACTIVE_VOID_FACTOR
      end

      def build_settlement_status(outcome)
        return Bet::VOIDED if active_void_factor?(outcome)

        outcome['result'] == WIN_RESULT ? Bet::WON : Bet::LOST
      end

      def settlement_error!(bet, error)
        invalid_bet_ids.push(bet.id)
        log_job_message(:error, message: 'Bet cannot be settled',
                                bet_id: bet.id,
                                reason: error.message)
      end

      def proceed_bets(external_id)
        get_settled_bets(external_id)
          .each { |bet| Bets::SettlementWorker.perform_async(bet.id) }
      end

      def bets_by_external_id(external_id)
        Bet
          .joins(:odd)
          .where(odds: { external_id: external_id })
      end

      def get_settled_bets(external_id)
        bets_by_external_id(external_id).where.not(id: invalid_bet_ids)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
