# frozen_string_literal: true

module OddsFeed
  module Radar
    class BetCancelHandler < RadarMessageHandler
      SUITABLE_BET_STATUSES = [
        Bet::ACCEPTED,
        Bet::SETTLED,
        Bet::PENDING_MANUAL_SETTLEMENT
      ].freeze

      attr_accessor :batch_size

      def initialize(payload)
        super(payload)
        @batch_size = 20
      end

      def handle
        validate_message!
        cancel_bets
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

      def cancel_bets
        bets.find_each(batch_size: batch_size) { |bet| cancel_bet(bet) }
      end

      def bets
        @bets ||= Bet
                  .joins(odd: :market)
                  .includes(:winning, :placement_entry)
                  .where(markets: { external_id: market_external_ids })
                  .where(status: SUITABLE_BET_STATUSES)
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

      def cancel_bet(bet)
        ActiveRecord::Base.transaction do
          return_money(bet)

          bet.cancel_by_system!
        end
      rescue StandardError => error
        log_job_message(:error, message: 'Bet was not cancelled!',
                                bet_id: bet.id,
                                reason: error.message,
                                error_object: error)
      end

      def return_money(bet)
        requests = EntryRequests::Factories::BetCancellation.call(bet: bet)
        requests.each { |request| proceed_entry_request(request) }
      end

      def proceed_entry_request(request)
        EntryRequests::ProcessingService.call(entry_request: request)
      end
    end
  end
end
