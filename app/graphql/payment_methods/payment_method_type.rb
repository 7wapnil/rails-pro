module PaymentMethods
  PaymentMethodType = GraphQL::ObjectType.define do
    name 'PaymentMethod'

    field :name, !types.String,
          resolve: ->(obj, _args, _ctx) { obj }

    field :code, !types.String,
          resolve: ->(obj, _args, _ctx) { obj }

    field :type, !types.String,
          resolve: ->(_obj, _args, _ctx) { 'fiat' }

    field :fields, !types[PaymentDetailsType],
          resolve: ->(obj, _args, _ctx) do
            SafeCharge::Withdraw::WITHDRAW_MODE_FIELDS[obj]
          end
  end
end
