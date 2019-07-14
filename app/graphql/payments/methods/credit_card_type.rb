# frozen_string_literal: true

module Payments
  module Methods
    CreditCardType = GraphQL::ObjectType.define do
      name 'PaymentMethodCreditCard'

      field :title, !types.String,
            resolve: ->(obj, _args, _ctx) { "**** #{obj.last_four_digits}" }

      field :holderName, !types.String, property: :holder_name
      field :lastFourDigits, !types.String, property: :last_four_digits
    end
  end
end
