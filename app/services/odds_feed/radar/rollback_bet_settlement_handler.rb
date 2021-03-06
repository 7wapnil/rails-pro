# frozen_string_literal: true

module OddsFeed
  module Radar
    class RollbackBetSettlementHandler < RadarMessageHandler
      include WebsocketEventEmittable

      BATCH_SIZE = 100

      def handle
        rollback_markets
        rollback_bet_legs
      end

      private

      def rollback_markets
        Market
          .where(external_id: markets_ids)
          .each { |market| rollback_market(market) }
      end

      def markets_ids
        @markets_ids ||= Array
                         .wrap(input_data['market'])
                         .map { |market_data| generate_market_id(market_data) }
      end

      def generate_market_id(market_data)
        OddsFeed::Radar::ExternalId
          .new(event_id: event_id,
               market_id: market_data['id'],
               specs: market_data['specifiers'].to_s)
          .generate
      end

      def event_id
        input_data['event_id']
      end

      def input_data
        payload['rollback_bet_settlement']
      end

      def rollback_market(market)
        market.rollback_status!
      rescue StandardError => error
        log_job_message(:error, message: 'Market rollback settlement error',
                                market_id: market.external_id,
                                status: market.status,
                                previous_status: market.previous_status,
                                reason: error.message,
                                error_object: error)
      end

      def rollback_bet_legs
        bet_legs.find_each(batch_size: BATCH_SIZE) do |bet_leg|
          rollback_bet_leg(bet_leg)
        end
      end

      def bet_legs
        BetLeg.joins(:bet, :market)
              .where(bets: { status: [Bet::ACCEPTED,
                                      Bet::SETTLED,
                                      Bet::PENDING_MANUAL_SETTLEMENT] })
              .where(markets: { external_id: markets_ids })
              .lock!
      end

      def rollback_bet_leg(bet_leg)
        ::Bets::RollbackSettlementWorker.perform_async(bet_leg.id)
      end
    end
  end
end
