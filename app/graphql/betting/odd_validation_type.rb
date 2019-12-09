# frozen_string_literal: true

module Betting
  OddValidationType = GraphQL::ObjectType.define do
    name 'OddValidation'

    field :oddId, !types.ID, property: :odd_id
    field :valid, !types.Boolean, property: :valid?
    field :errorMessages, types[types.String], property: :error_messages
  end
end
