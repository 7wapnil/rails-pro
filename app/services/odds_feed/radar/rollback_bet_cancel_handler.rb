# frozen_string_literal: true

module OddsFeed
  module Radar
    class RollbackBetCancelHandler < RadarMessageHandler
      include WebsocketEventEmittable

      attr_accessor :batch_size

      def initialize(payload)
        super(payload)
        @batch_size = 20
      end

      def handle
        validate_message!
        rollback_market_statuses
        rollback_bets

        emit_websocket
      end

      private

      def input_data
        @payload['rollback_bet_cancel']
      end

      def validate_message!
        return if event_id && markets.any?

        raise OddsFeed::InvalidMessageError, @payload
      end

      def markets
        Array.wrap(input_data['market'])
      end

      def rollback_market_statuses
        Market
          .where(external_id: market_external_ids)
          .each { |market| rollback_market_status(market) }
      end

      def rollback_market_status(market)
        market.rollback_status!
      rescue StandardError => error
        log_job_failure(error)
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

      def rollback_bets
        bets.find_each(batch_size: batch_size)
            .each { |bet| rollback_bet(bet) }
      end

      def bets
        @bets ||= Bet
                  .joins(:market)
                  .includes(:winning_rollback_entry, :placement_rollback_entry)
                  .where(markets: { external_id: market_external_ids })
      end

      def rollback_bet(bet)
        ActiveRecord::Base.transaction do
          rollback_money(bet)

          return bet.accepted! unless bet.market.settled?

          bet.settled!
        end
      rescue StandardError => error
        log_job_failure(
          "Bet cancel for bet #{bet.id} has not been rollbacked!\n" \
          "Reason: #{error}"
        )
      end

      def rollback_money(bet)
        requests = EntryRequests::Factories::RollbackBetCancellation
                   .call(bet: bet)
        requests.each { |request| proceed_entry_request(request) }
      end

      def proceed_entry_request(request)
        EntryRequests::RollbackBetCancellationWorker.perform_async(request.id)
      end
    end
  end
end
