# frozen_string_literal: true

module Mts
  module Messages
    class SingleBetValidationRequest < ::Mts::Messages::ValidationRequest
      private

      def selections
        bet.bet_legs.includes(:odd, :event).map do |bet_leg|
          {
            event_id: bet_leg.event.external_id,
            id: Mts::UofId.id(bet_leg.odd),
            odds: Mts::MtsDecimal.from_number(bet_leg.odd_value)
          }
        end
      end

      def formatted_bets
        [{
          id: [ticket_id, 0].join('_'),
          selected_systems: single_bet_selected_systems,
          stake: {
            value: (bet.base_currency_amount * STAKE_MULTIPLIER).to_i,
            type: DEFAULT_STAKE_TYPE
          }
        }.merge(selection_refs(bet))]
      end

      def single_bet_selected_systems
        [1]
      end

      def selection_refs(_bet)
        {
          selection_refs: [{
            selection_index: 0,
            banker: false
          }]
        }
      end
    end
  end
end
