# frozen_string_literal: true

module Mts
  module Messages
    class ComboBetsValidationRequest < ::Mts::Messages::ValidationRequest
      private

      def selections
        bet_legs.map do |bet_leg|
          {
            event_id: bet_leg.event.external_id,
            id: Mts::UofId.id(bet_leg.odd),
            odds: Mts::MtsDecimal.from_number(bet_leg.odd_value)
          }
        end
      end

      def formatted_bets
        [{
          id: [ticket_id, 'bet', 0].join('_'),
          selected_systems: combo_bets_selected_systems,
          stake: {
            value: (bet.base_currency_amount * STAKE_MULTIPLIER).to_i,
            type: DEFAULT_STAKE_TYPE
          },
          selection_refs: combo_bets_selection_refs
        }]
      end

      def combo_bets_selected_systems
        [bet_legs.length]
      end

      def combo_bets_selection_refs
        bet_legs.map.with_index do |_bet_leg, index|
          {
            selection_index: index,
            banker: false
          }
        end
      end

      def bet_legs
        @bet_legs ||= bet.bet_legs.order(id: :asc)
      end
    end
  end
end
