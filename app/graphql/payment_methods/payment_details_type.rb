module PaymentMethods
  PaymentDetailsType = GraphQL::ObjectType.define do
    name 'PaymentDetails'

    field :name, !types.String,
          resolve: ->(obj, _args, _ctx) { obj[:name] }

    field :code, !types.String,
          resolve: ->(obj, _args, _ctx) { obj[:code] }

    field :type, !types.String,
          resolve: ->(obj, _args, _ctx) { obj[:type] }
  end
end
