# frozen_string_literal: true

module Payments
  module Withdrawals
    PaymentMethodType = GraphQL::ObjectType.define do
      name 'WithdrawalsPaymentMethod'

      field :id, !types.ID
      field :name, !types.String,
            resolve: ->(obj, _args, _ctx) do
              I18n.t("payments.withdrawals.payment_methods.#{obj.mode}.title",
                     default: obj.mode.humanize)
            end

      field :note, types.String,
            resolve: ->(obj, _args, ctx) do
              range = ::Withdrawals::PaymentMethodRangeSelector.call(
                customer: ctx[:current_customer],
                payment_method: obj.mode
              )

              I18n.t("payments.withdrawals.payment_methods.#{obj.mode}.range",
                     **range, default: nil)
            end

      field :description, types.String,
            resolve: ->(obj, _args, _ctx) do
              I18n.t(
                "payments.withdrawals.payment_methods.#{obj.mode}.description",
                default: nil
              )
            end

      field :code, !types.String, property: :mode

      field :details, ::Payments::Withdrawals::PaymentMethodDetailsUnion,
            resolve: ->(obj, _args, _ctx) do
              OpenStruct.new(
                id: obj.id,
                payment_method: obj.mode,
                **obj.details.symbolize_keys
              )
            end

      field :currencyKind, types.String,
            resolve: ->(obj, _args, _ctx) do
              ::Payments::Methods::METHOD_PROVIDERS.dig(obj.mode,
                                                        :currency_kind)
            end

      field :currencyCode, types.String,
            resolve: ->(obj, _args, _ctx) do
              ::Payments::Methods::METHOD_PROVIDERS.dig(obj.mode, :currency)
            end
    end
  end
end
