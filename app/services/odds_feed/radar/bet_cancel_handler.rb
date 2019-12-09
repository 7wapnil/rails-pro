# frozen_string_literal: true

module OddsFeed
  module Radar
    class BetCancelHandler < RadarMessageHandler
      SUITABLE_BET_STATUSES = [
        Bet::ACCEPTED,
        Bet::SETTLED,
        Bet::PENDING_MANUAL_SETTLEMENT
      ].freeze
      SUITABLE_BET_LEG_SETTLEMENT_STATUSES = [
        BetLeg::WON,
        BetLeg::LOST,
        nil
      ].freeze

      attr_accessor :batch_size

      def initialize(payload)
        super(payload)
        @batch_size = 20
      end

      def handle
        validate_message!
        cancel_bet_legs
      end

      private

      def input_data
        payload['bet_cancel']
      end

      def markets
        Array.wrap(input_data['market'])
      end

      def validate_message!
        return if event_id && markets.any?

        raise OddsFeed::InvalidMessageError, payload
      end

      def event_id
        input_data['event_id']
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

      def cancel_bet_legs
        bet_legs.find_each(batch_size: batch_size) do |bet_leg|
          cancel_bet_leg(bet_leg, bet_leg.bet)
        end
      end

      def bet_legs
        @bet_legs ||= BetLeg
                      .joins(:bet, odd: :market)
                      .includes(bet: %i[bet_legs winning placement_entry])
                      .where(markets: { external_id: market_external_ids })
                      .merge(bet_legs_with_suitable_settlement_statuses)
                      .merge(bets_with_suitable_statuses)
                      .merge(bets_with_start_time)
                      .merge(bets_with_end_time)
                      .lock!
      end

      def bet_legs_with_suitable_settlement_statuses
        BetLeg.where(settlement_status: SUITABLE_BET_LEG_SETTLEMENT_STATUSES)
      end

      def bets_with_suitable_statuses
        Bet.where(status: SUITABLE_BET_STATUSES)
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

      def cancel_bet_leg(bet_leg, bet)
        ::Bets::Cancel.call(bet: bet, bet_leg: bet_leg)
      rescue StandardError => error
        log_error_message(error, bet, bet_leg)
      end

      def log_error_message(error, bet, bet_leg)
        log_job_message(:error, message: 'Bet leg was not cancelled!',
                                bet_id: bet.id,
                                bet_leg_id: bet_leg.id,
                                reason: error.message,
                                error_object: error)
      end
    end
  end
end
