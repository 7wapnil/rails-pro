module OddsFeed
  module Radar
    # rubocop:disable Metrics/ClassLength
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
          message: I18n.t('logs.odds_feed.low_certainty'),
          event_id: event_external_id,
          certainty_level: certainty_level
        )
      end

      def markets
        @markets ||= Array.wrap(input_data['outcomes']['market'])
      end

      def process_outcomes_for(market_data)
        market_data['outcome'].each do |outcome|
          generator = ExternalId.new(event_id: input_data['event_id'],
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

      def event_external_id
        input_data['event_id']
      end

      def certainty_level
        input_data['certainty'].to_i
      end

      def update_bets(external_id, outcome)
        log_job_message(
          :debug, "Settling bets for odd with EID #{external_id}"
        )

        bets = bets_by_external_id(external_id)
        settle_bets(bets, outcome)

        bets = get_settled_bets(external_id)
        logger_level = bets.size.positive? ? :info : :debug
        log_job_message(logger_level, "#{bets.size} bets settled")
      end

      def settle_bets(bets, outcome)
        bets.each { |bet| settle_bet(bet, outcome) }
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

      def proceed_bets(external_id)
        get_settled_bets(external_id)
          .each { |bet| Bets::Settlement::Proceed.call(bet: bet) }
      end

      def bets_by_external_id(external_id)
        Bet
          .joins(:odd)
          .where(odds: { external_id: external_id })
      end

      def get_settled_bets(external_id)
        bets_by_external_id(external_id).where.not(id: invalid_bet_ids)
      end

      def event
        @event ||= Event.find_by(external_id: input_data['event_id'])
      end

      def emit_websocket
        unless event
          return log_job_message(
            :warn,
            message: 'Event not found',
            event_id: input_data['event_id']
          )
        end

        WebSocket::Client.instance.trigger_event_update(event)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
