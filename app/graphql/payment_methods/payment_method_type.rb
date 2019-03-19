module PaymentMethods
  PaymentMethodType = GraphQL::ObjectType.define do
    name 'PaymentMethod'

    field :name, !types.String,
          resolve: ->(obj, _args, _ctx) do
            I18n.t("payment_methods.#{obj}.title", default: obj.humanize)
          end

    field :payment_note, !types.String,
          resolve: ->(obj, _args, _ctx) do
            I18n.t("payment_methods.#{obj}.payment_note", default: obj.humanize)
          end

    field :code, !types.String,
          resolve: ->(obj, _args, _ctx) { obj }

    field :type, !types.String,
          resolve: ->(_obj, _args, _ctx) { Currency::FIAT }

    field :fields, !types[PaymentDetailsType],
          resolve: ->(obj, _args, _ctx) do
            SafeCharge::Withdraw::WITHDRAW_MODE_FIELDS[obj]
          end
  end
end
