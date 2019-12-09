# frozen_string_literal: true

module OddsFeed
  module Radar
    class BetSettlementHandler < RadarMessageHandler
      include WebsocketEventEmittable

      CERTAINTY_LIMIT = 2
      UNCERTAIN_PRODUCER = '1'

      def handle
        validate_message!
        process_outcomes
        settle_markets
        emit_websocket
      end

      private

      def validate_message!
        return unless input_data.dig('outcomes', 'market').nil?

        raise OddsFeed::InvalidMessageError, 'Invalid bet_settlement payload'
      end

      def input_data
        payload['bet_settlement']
      end

      def process_outcomes
        markets
          .reject { |market_data| skip_uncertain_settlement?(market_data) }
          .each { |market_data| settle_bets_for_market(market_data) }
      end

      def markets
        @markets ||= Array.wrap(input_data['outcomes']['market'])
      end

      def skip_uncertain_settlement?(market_data)
        market_template = find_market_template_for(market_data['id'])

        market_template &&
          !market_template.payload['products'].include?(UNCERTAIN_PRODUCER) &&
          certainty_level < CERTAINTY_LIMIT
      end

      def find_market_template_for(external_id)
        market_templates
          .find { |market_template| market_template.external_id == external_id }
      end

      def market_templates
        @market_templates ||= MarketTemplate
                              .select(:id, :external_id, :payload)
                              .where(external_id: market_template_external_ids)
      end

      def market_template_external_ids
        markets.map { |market_data| market_data['id'] }
      end

      def certainty_level
        input_data['certainty'].to_i
      end

      def settle_bets_for_market(market_data)
        Array.wrap(market_data['outcome'])
             .each { |outcome| settle_bets_for_outcome(market_data, outcome) }
      end

      def settle_bets_for_outcome(market_data, outcome)
        external_id = ExternalId.new(
          event_id: event_id,
          market_id: market_data['id'],
          specs: market_data['specifiers'],
          outcome_id: outcome['id']
        ).generate

        find_bet_legs_by_odd_id(external_id).each do |bet_leg|
          bet_leg.lock!
          bet_leg.bet.lock!

          settle_bet(bet_leg, outcome)
        end
      end

      def find_bet_legs_by_odd_id(external_id)
        BetLeg.joins(:bet, :odd)
              .where(bets: { status: Bet::ACCEPTED })
              .where(odds: { external_id: external_id })
              .includes(:bet)
      end

      def settle_bet(bet_leg, outcome)
        ::Bets::SettlementWorker.perform_async(
          bet_leg.id,
          outcome['void_factor'],
          outcome['result']
        )
      end

      def settle_markets
        Market
          .where(external_id: market_external_ids)
          .each(&:settled!)
      end

      def market_external_ids
        markets.map { |payload| generate_market_id(payload) }
      end

      def generate_market_id(market_data)
        ExternalId.new(
          event_id: event_id,
          market_id: market_data['id'],
          specs: market_data['specifiers']
        ).generate
      end
    end
  end
end
