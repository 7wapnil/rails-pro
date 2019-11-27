# frozen_string_literal: true

module Payments
  module Methods
    IdebitType = GraphQL::ObjectType.define do
      name 'PaymentMethodIdebit'

      field :id, !types.ID
      field :title, !types.String, property: :name

      field :name, !types.String
      field :userPaymentOptionId, !types.String,
            property: :user_payment_option_id
    end
  end
end
