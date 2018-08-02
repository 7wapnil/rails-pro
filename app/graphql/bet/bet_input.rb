module Bet
  BetInput = GraphQL::InputObjectType.define do
    name 'BetInput'

    argument :amount, !types.Float
    argument :oddId, !types.Int
  end
end
