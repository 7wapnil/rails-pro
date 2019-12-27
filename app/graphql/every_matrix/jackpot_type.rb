# frozen_string_literal: true

module EveryMatrix
  JackpotType = GraphQL::ObjectType.define do
    name 'JackpotType'

    field :amount, !types.Int
  end
end
