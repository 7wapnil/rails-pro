# frozen_string_literal: true

module Payments
  module Withdrawals
    PaymentMethodType = GraphQL::ObjectType.define do
      name 'WithdrawalsPaymentMethod'

      field :name, !types.String,
            resolve: ->(obj, _args, _ctx) do
              I18n.t("payments.withdrawal.payment_methods.#{obj}.title",
                     default: obj.humanize)
            end

      field :note, !types.String,
            resolve: ->(obj, _args, _ctx) do
              I18n.t("payments.withdrawal.payment_methods.#{obj}.note",
                     default: obj.humanize)
            end

      field :code, !types.String, property: :itself
      field :currencyCode, types.String,
            resolve: ->(obj, _args, _ctx) do
              ::Payments::Methods::METHOD_PROVIDERS.dig(obj, :currency)
            end
    end
  end
end
