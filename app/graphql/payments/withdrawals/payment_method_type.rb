# frozen_string_literal: true

module Payments
  module Withdrawals
    PaymentMethodType = GraphQL::ObjectType.define do
      name 'WithdrawalsPaymentMethod'

      field :name, !types.String,
            resolve: ->(obj, _args, _ctx) do
              I18n.t("payments.withdrawals.payment_methods.#{obj}.title",
                     default: obj.humanize)
            end

      field :note, types.String,
            resolve: ->(obj, _args, ctx) do
              range = ::Withdrawals::PaymentMethodRangeSelector.call(
                customer: ctx[:current_customer],
                payment_method: obj
              )

              I18n.t("payments.withdrawals.payment_methods.#{obj}.range",
                     **range, default: nil)
            end

      field :description, types.String,
            resolve: ->(obj, _args, _ctx) do
              I18n.t("payments.withdrawals.payment_methods.#{obj}.description",
                     default: nil)
            end

      field :code, !types.String, property: :itself
      field :currencyCode, types.String,
            resolve: ->(obj, _args, _ctx) do
              ::Payments::Methods::METHOD_PROVIDERS.dig(obj, :currency)
            end
    end
  end
end
