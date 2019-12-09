module Betting
  BetPlacementType = GraphQL::ObjectType.define do
    name 'BetPlacement'

    field :success, !types.Boolean
    field :message, types.String
    field :bet, BetType
    field :oddId, types.ID, property: :odd_id
  end
end
