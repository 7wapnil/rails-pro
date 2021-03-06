# frozen_string_literal: true

module Payments
  module Deposits
    PaymentMethodType = GraphQL::ObjectType.define do
      name 'DepositsPaymentMethod'

      field :name, !types.String, resolve: ->(obj, _args, _ctx) do
        I18n.t("payments.deposits.payment_methods.#{obj.name}.title",
               default: obj.name.humanize)
      end
      field :note, types.String, resolve: ->(obj, _args, _ctx) do
        I18n.t("payments.deposits.payment_methods.#{obj.name}.note",
               default: nil)
      end

      field :code, !types.String, property: :name
      field :currency, Currencies::CurrencyType
      field :maxAmount, types.Float, property: :max_amount
      field :minAmount, types.Float, property: :min_amount
    end
  end
end
