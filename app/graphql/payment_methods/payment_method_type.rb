module PaymentMethods
  PaymentMethodType = GraphQL::ObjectType.define do
    name 'PaymentMethod'

    field :name, !types.String,
          resolve: ->(obj, _args, _ctx) do
            I18n.t("payment_methods.#{obj}.title",
                   default: obj.payment_method.humanize)
          end

    field :note, !types.String,
          resolve: ->(obj, _args, _ctx) do
            I18n.t("payment_methods.#{obj}.note",
                   default: obj.payment_method.humanize)
          end

    field :code, !types.String,
          resolve: ->(obj, _args, _ctx) { obj.payment_method }

    field :kind, !types.String,
          resolve: ->(_obj, _args, _ctx) { Currency::FIAT }
  end
end
