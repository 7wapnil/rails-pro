module Betting
  BetPlacementType = GraphQL::ObjectType.define do
    name 'BetPlacement'

    field :id, !types.ID
    field :success, !types.Boolean
    field :message, types.String
    field :bet, BetType
  end
end
