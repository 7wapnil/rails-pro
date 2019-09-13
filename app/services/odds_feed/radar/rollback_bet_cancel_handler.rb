# frozen_string_literal: true

module OddsFeed
  module Radar
    class RollbackBetCancelHandler < RadarMessageHandler
      attr_accessor :batch_size

      def initialize(payload)
        super(payload)
        @batch_size = 20
      end

      def handle
        validate_message!
        rollback_bets
      end

      private

      def input_data
        @payload['rollback_bet_cancel']
      end

      def validate_message!
        return if event_id && markets.any?

        raise OddsFeed::InvalidMessageError, @payload
      end

      def event_id
        input_data['event_id']
      end

      def markets
        Array.wrap(input_data['market'])
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
                  .cancelled_by_system
                  .where(markets: { external_id: market_external_ids })
                  .merge(bets_with_start_time)
                  .merge(bets_with_end_time)
      end

      def bets_with_start_time
        return {} unless input_data['start_time']

        Bet.where('bets.created_at >= ?',
                  parse_timestamp(input_data['start_time']))
      end

      def bets_with_end_time
        return {} unless input_data['end_time']

        Bet.where('bets.created_at < ?',
                  parse_timestamp(input_data['end_time']))
      end

      def rollback_bet(bet)
        ActiveRecord::Base.transaction do
          rollback_money(bet)

          return settle_bet(bet) if bet.settlement_status

          bet.rollback_system_cancellation_with_acceptance!
        end
      rescue StandardError => error
        log_job_message(
          :error,
          message: 'Bet cancel for bet was not rollbacked!',
          bet_id: bet.id,
          reason: error.message,
          error_object: error
        )
      end

      def rollback_money(bet)
        requests = EntryRequests::Factories::RollbackBetCancellation
                   .call(bet: bet)
        requests.each { |request| proceed_entry_request(request) }
      end

      def proceed_entry_request(request)
        EntryRequests::ProcessingService.call(entry_request: request)
      end

      def settle_bet(bet)
        bet.rollback_system_cancellation_with_settlement!
      end
    end
  end
end
