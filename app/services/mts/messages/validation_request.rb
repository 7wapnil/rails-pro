module Mts
  module Messages
    # TODO: Extract parts to different classes
    class ValidationRequest # rubocop:disable  Metrics/ClassLength
      SUPPORTED_BETS_PER_REQUEST = 1

      def initialize(context, bets)
        raise NotImplementedError if bets.length > SUPPORTED_BETS_PER_REQUEST
        @context = context
        @bets = bets
      end

      def to_h
        root_attributes.merge(
          sender: sender,
          selections: selections,
          bets: bets
        )
      end

      def to_formatted_hash
        format_keys(to_h)
      end

      private

      # message structure

      def root_attributes
        {
          version: '2.0',
          timestampUtc: timestamp,
          ticketId: ticket_id
        }
      end

      def sender
        {
          currency: bets_currency,
          terminal_id: 'Tallinn-1',
          channel: 'internet',
          shop_id: nil,
          bookmaker_id: 7669,
          end_customer: end_customer,
          limit_id: 424
        }
      end

      # TODO: Implement end_customer data from context
      def end_customer
        {
          ip: '127.0.0.1',
          language_id: 'EN',
          device_id: '1234test',
          id: @bets.first.customer.id.to_s,
          confidence: 10_000
        }
      end

      def selections
        @bets.map do |bet|
          {
            event_id: event_id(bet),
            id: bet.odd.external_id,
            odds: decimal_formatter(bet.odd_value)
          }
        end
      end

      def bets
        @bets.map.with_index do |bet, index|
          {
            id: [ticket_id, index].join('_'),
            selected_systems: single_bet_selected_systems,
            stake: {
              value: decimal_formatter(bet.amount),
              type: 'total'
            }
          }.merge(selection_refs(bet))
        end
      end

      # getters

      # TODO: Figure out where to take id
      def event_id(*)
        11_050_343
      end

      def timestamp
        @timestamp ||= Time.now.to_i
      end

      def ticket_id
        'MTS_Test_' + @timestamp.to_s
      end

      def bets_currency
        @bets.first.currency.code
      end

      def single_bet_selected_systems
        [1]
      end

      def selection_refs(_bet)
        { selection_refs: [
          {
            selection_index: 0,
            banker: false
          }
        ] }
      end

      # formatter

      def format_keys(hash)
        formatted_hash = {}
        hash.each do |k, v|
          value = v
          value = format_keys(v) if v.is_a?(Hash)
          if v.is_a?(Array)
            value =
              v.map { |e| e.is_a?(Hash) ? format_keys(e) : e }
          end
          formatted_hash[k.to_s.camelize(:lower)] =
            value
        end
        formatted_hash
      end

      def decimal_formatter(decimal)
        (decimal * 10_000).round
      end
    end
  end
end
