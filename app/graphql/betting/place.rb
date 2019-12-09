module Betting
  class Place < ::Base::Resolver
    type types[BetPlacementType]

    argument :bets, types[BetInput]
    mark_as_trackable

    def resolve(_obj, args)
      PlaceResolver.call(
        bets_payload: args[:bets],
        impersonated_by: @impersonated_by,
        customer: @current_customer,
        combo_bets: false
      )
    end
  end
end
