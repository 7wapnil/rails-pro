module Mts
  module Messages
    class ValidationRequest
      def self.build(*)
        new
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

      ## message structure

      def root_attributes
        {
          version: '2.0',
          timestampUtc: timestamp,
          ticketId: ticket_id
        }
      end

      def sender
        {
          currency: 'EUR',
          terminal_id: 'Tallinn-1',
          channel: 'internet',
          shop_id: nil,
          bookmaker_id: 7669,
          end_customer: end_customer,
          limit_id: 424
        }
      end

      def end_customer
        {
          ip: '127.0.0.1',
          language_id: 'EN',
          device_id: '1234test',
          id: '1234test',
          confidence: 10_000
        }
      end

      def selections
        [
          {
            event_id: 11_050_343,
            id: 'lcoo:42/1/*/X',
            odds: 28_700
          }
        ]
      end

      def bets
        [
          {
            id: ticket_id + '_0',
            selected_systems: [
              1
            ],
            stake: {
              value: 10_000,
              type: 'total'
            }
          }.merge(selection_refs)
        ]
      end

      ## getters

      def timestamp
        @timestamp ||= Time.now.to_i
      end

      def ticket_id
        'MTS_Test_' + @timestamp.to_s
      end

      def selection_refs(*)
        { selection_refs: [
          {
            selection_index: 0,
            banker: false
          }
        ] }
      end

      ## formatter

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
    end
  end
end
