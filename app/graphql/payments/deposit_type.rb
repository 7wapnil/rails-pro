# frozen_string_literal: true

module Payments
  DepositType = GraphQL::ObjectType.define do
    name 'DepositType'

    field :url, !types.String
    field :message, types.String
  end
end
