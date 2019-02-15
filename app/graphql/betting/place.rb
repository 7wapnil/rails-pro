module Betting
  class Place < ::Base::Resolver
    type types[BetPlacementType]

    argument :bets, types[BetInput]

    def resolve(_obj, args)
      PlaceResolver.call(
        args: args,
        impersonated_by: @impersonated_by,
        customer: @current_customer
      )
    end
  end
end
