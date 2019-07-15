# frozen_string_literal: true

module Payments
  module Methods
    CreditCardType = GraphQL::ObjectType.define do
      name 'PaymentMethodCreditCard'

      field :id, !types.ID
      field :title, !types.String,
            resolve: ->(obj, _args, _ctx) do
              "**** #{obj.masked_account_number&.last(4)}"
            end

      field :holderName, !types.String,
            property: :holder_name
      field :lastFourDigits, !types.String,
            resolve: ->(obj, _args, _ctx) { obj.masked_account_number&.last(4) }
      field :tokenId, !types.String,
            property: :token_id
      field :maskedAccountNumber, !types.String,
            property: :masked_account_number
    end
  end
end
