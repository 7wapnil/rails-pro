module Transactions
  TransactionType = GraphQL::ObjectType.define do
    name 'Transactions'

    field :id, !types.ID
    field :customer_id, types.ID
    field :status, types.String
    field :mode, types.String
    field :currencyCode, types.String,
          resolve: ->(obj, _args, _ctx) { obj.currency.code }
    field :amount, types.Float
    field :comment, types.String
    field :created_at, types.String do
      resolve ->(obj, _args, _ctx) { obj.created_at.strftime('%e.%m.%y') }
    end
    field :updated_at, types.String do
      resolve ->(obj, _args, _ctx) { obj.updated_at.strftime('%e.%m.%y') }
    end
  end
end
