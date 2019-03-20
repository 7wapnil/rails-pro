module PaymentMethods
  PaymentMethodType = GraphQL::ObjectType.define do
    name 'PaymentMethod'

    field :name, !types.String,
          resolve: ->(obj, _args, _ctx) do
            I18n.t("payment_methods.#{obj}.title",
                   default: obj.first.humanize)
          end

    field :availability, !types.Boolean,
          resolve: ->(obj, _args, _ctx) { obj.second }

    field :payment_note, !types.String,
          resolve: ->(obj, _args, _ctx) do
            I18n.t("payment_methods.#{obj}.payment_note",
                   default: obj.first.humanize)
          end

    field :code, !types.String,
          resolve: ->(obj, _args, _ctx) { obj.first }

    field :type, !types.String,
          resolve: ->(_obj, _args, _ctx) { Currency::FIAT }

    field :fields, !types[PaymentDetailsType],
          resolve: ->(obj, _args, _ctx) do
            return {} unless obj.second

            SafeCharge::Withdraw::WITHDRAW_MODE_FIELDS[obj.first]
          end
  end
end
