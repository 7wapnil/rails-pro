# frozen_string_literal: true

module Betting
  ComboBetsValidationType = GraphQL::ObjectType.define do
    name 'ComboBetsValidation'

    field :valid, !types.Boolean, property: :valid?
    field :generalMessages, !types[types.String], property: :general_messages
    field :odds, !types[::Betting::OddValidationType]
  end
end
