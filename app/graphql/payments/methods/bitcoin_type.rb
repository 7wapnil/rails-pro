# frozen_string_literal: true

module Payments
  module Methods
    BitcoinType = GraphQL::ObjectType.define do
      name 'PaymentMethodBitcoin'

      field :id, !types.ID
      field :title, !types.String,
            resolve: ->(*) { ::Payments::Methods::BITCOIN.humanize }
      field :isEditable, !types.Boolean, resolve: ->(*) { true }
      field :address, !types.String, property: :address
    end
  end
end
