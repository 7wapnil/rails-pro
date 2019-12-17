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
        rollback_bet_legs
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

      def rollback_bet_legs
        bet_legs.find_each(batch_size: batch_size)
                .each { |bet_leg| rollback_bet_leg(bet_leg.bet, bet_leg) }
      end

      def bet_legs
        @bet_legs ||= BetLeg
                      .joins(:bet, :market)
                      .includes(:event, bet: %i[winning_rollback_entry
                                                placement_rollback_entry
                                                winning])
                      .cancelled_by_system
                      .where(markets: { external_id: market_external_ids })
                      .merge(bets_with_start_time)
                      .merge(bets_with_end_time)
                      .lock!
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

      def rollback_bet_leg(bet, bet_leg)
        ::Bets::RollbackCancel.call(bet: bet, bet_leg: bet_leg)
      rescue StandardError => error
        log_error_message(error, bet, bet_leg)
      end

      def log_error_message(error, bet, bet_leg)
        log_job_message(:error, message: 'Bet cancel was not rollbacked!',
                                bet_id: bet.id,
                                bet_leg_id: bet_leg.id,
                                reason: error.message,
                                error_object: error)
      end
    end
  end
end
