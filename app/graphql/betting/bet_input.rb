# frozen_string_literal: true

module Betting
  BetInput = GraphQL::InputObjectType.define do
    name 'BetInput'

    argument :amount, !types.Float
    argument :odds, types[OddInput]
    argument :currencyCode, !types.String
    argument :oddsChange, types.Boolean
  end
end
