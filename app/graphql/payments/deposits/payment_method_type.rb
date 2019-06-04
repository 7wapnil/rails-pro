# frozen_string_literal: true

module Payments
  module Deposits
    PaymentMethodType = GraphQL::ObjectType.define do
      name 'DepositsPaymentMethod'

      field :name, !types.String,
            resolve: ->(obj, _args, _ctx) do
              I18n.t("payments.deposit.payment_methods.#{obj}.title",
                     default: obj.humanize)
            end

      field :note, !types.String,
            resolve: ->(obj, _args, _ctx) do
              I18n.t("payments.deposit.payment_methods.#{obj}.note",
                     default: obj.humanize)
            end

      field :code, !types.String, property: :itself
    end
  end
end
