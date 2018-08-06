module Betting
  BetInput = GraphQL::InputObjectType.define do
    name 'BetInput'

    argument :amount, !types.Float
    argument :oddId, !types.String
    argument :currency, !types.String
  end
end
