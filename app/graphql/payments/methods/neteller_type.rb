# frozen_string_literal: true

module Payments
  module Methods
    NetellerType = GraphQL::ObjectType.define do
      name 'PaymentMethodNeteller'

      field :title, !types.String, property: :account_id
      field :accountId, !types.String, property: :account_id
      field :secureId, !types.String, property: :secure_id
    end
  end
end
