module PaymentMethods
  PaymentMethodType = GraphQL::ObjectType.define do
    name 'PaymentMethod'

    field :name, !types.String,
          resolve: ->(obj, _args, _ctx) do
            I18n.t("payment_methods.#{obj}.title",
                   default: obj.payment_method.humanize)
          end

    field :availability, !types.Boolean,
          resolve: ->(obj, _args, _ctx) { obj.available }

    field :payment_note, !types.String,
          resolve: ->(obj, _args, _ctx) do
            I18n.t("payment_methods.#{obj}.payment_note",
                   default: obj.payment_method.humanize)
          end

    field :code, !types.String,
          resolve: ->(obj, _args, _ctx) { obj.payment_method }

    field :type, !types.String,
          resolve: ->(_obj, _args, _ctx) { Currency::FIAT }

    field :fields, !types[PaymentDetailsType],
          resolve: ->(obj, _args, _ctx) do
            return {} unless obj.available

            SafeCharge::Withdraw::WITHDRAW_MODE_FIELDS[obj.payment_method]
          end
  end
end
