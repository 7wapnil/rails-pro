# frozen_string_literal: true

module OddsFeed
  module Radar
    class RollbackBetSettlementHandler < RadarMessageHandler
      include WebsocketEventEmittable

      BATCH_SIZE = 100

      def handle
        rollback_markets
        rollback_bets
      end

      private

      def rollback_markets
        Market
          .includes(:bets)
          .where(external_id: markets_ids)
          .each(&:rollback_status!)
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

      def rollback_bets
        bets.find_each(batch_size: BATCH_SIZE) { |bet| rollback_bet(bet) }
      end

      def bets
        @bets ||=
          Bet
          .joins(:market)
          .includes(:currency, :customer, :event, :winning)
          .settled
          .where(markets: { external_id: markets_ids })
      end

      def rollback_bet(bet)
        ActiveRecord::Base.transaction do
          rollback_winning(bet) if bet.won?

          bet.update(settlement_status: nil,
                     status: StateMachines::BetStateMachine::ACCEPTED)
        end
      rescue StandardError => error
        log_job_message(
          :error,
          message: 'Bet settlement was not rollbacked!',
          bet_id: bet.id,
          reason: error.message
        )
      end

      def rollback_winning(bet)
        entry_request = EntryRequests::Factories::Rollback.call(bet: bet)
        EntryRequests::RollbackWorker.perform_async(entry_request.id)
      end
    end
  end
end
