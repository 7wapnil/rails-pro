# frozen_string_literal: true

module Betting
  OddInput = GraphQL::InputObjectType.define do
    name 'OddInput'

    argument :id, !types.String
    argument :value, !types.Float
  end
end
