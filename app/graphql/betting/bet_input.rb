module Betting
  BetInput = GraphQL::InputObjectType.define do
    name 'BetInput'

    argument :amount, !types.Float
    argument :oddId, !types.String
    argument :oddValue, !types.Float
    argument :currencyCode, !types.String
  end
end
