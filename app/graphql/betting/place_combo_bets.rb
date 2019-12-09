# frozen_string_literal: true

module Betting
  class PlaceComboBets < ::Base::Resolver
    type BetPlacementType

    argument :bet, BetInput
    mark_as_trackable

    def resolve(_obj, args)
      PlaceResolver.call(
        bets_payload: args[:bet],
        impersonated_by: @impersonated_by,
        customer: @current_customer,
        combo_bets: true
      )
    end
  end
end
