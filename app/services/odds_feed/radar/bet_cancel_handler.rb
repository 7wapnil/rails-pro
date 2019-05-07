# frozen_string_literal: true

module OddsFeed
  module Radar
    class BetCancelHandler < RadarMessageHandler
      include WebsocketEventEmittable

      attr_accessor :batch_size

      def initialize(payload)
        super(payload)
        @batch_size = 20
      end

      def handle
        validate_message!
        update_markets_status
        cancel_bets

        emit_websocket
      end

      private

      def input_data
        @payload['bet_cancel']
      end

      def markets
        Array.wrap(input_data['market'])
      end

      def validate_message!
        return if event_id && markets.any?

        raise OddsFeed::InvalidMessageError, @payload
      end

      def update_markets_status
        Market.where(external_id: market_external_ids)
              .each(&:cancelled!)
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
        bets.find_each(batch_size: batch_size)
            .each { |bet| cancel_bet(bet) }
      end

      def bets
        @bets ||= Bet.joins(odd: :market)
                     .includes(:winning, :placement_entry)
                     .where(markets: { external_id: market_external_ids })
                     .merge(bets_with_start_time)
                     .merge(bets_with_end_time)
      end

      def bets_with_start_time
        return {} unless input_data['start_time']

        Bet.where('bets.created_at >= ?',
                  to_datetime(input_data['start_time']))
      end

      def bets_with_end_time
        return {} unless input_data['end_time']

        Bet.where('bets.created_at < ?',
                  to_datetime(input_data['end_time']))
      end

      def to_datetime(timestamp)
        Time.at(timestamp.to_i)
            .to_datetime
            .in_time_zone
      end

      def cancel_bet(bet)
        ActiveRecord::Base.transaction do
          return_money(bet)

          bet.cancelled_by_system!
        end
      rescue StandardError => error
        log_job_message(:error, message: 'Bet was not cancelled!',
                                bet_id: bet.id,
                                reason: error.message)
      end

      def return_money(bet)
        requests = EntryRequests::Factories::BetCancellation.call(bet: bet)
        requests.each { |request| proceed_entry_request(request) }
      end

      def proceed_entry_request(request)
        EntryRequests::BetCancellationWorker.perform_async(request.id)
      end
    end
  end
end
