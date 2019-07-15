# frozen_string_literal: true

module Payments
  module Methods
    NetellerType = GraphQL::ObjectType.define do
      name 'PaymentMethodNeteller'

      field :id, !types.ID
      field :title, !types.String, property: :account_id
      field :accountId, !types.String, property: :account_id
    end
  end
end
