module Transactions
  TransactionType = GraphQL::ObjectType.define do
    name 'Transactions'

    field :id, !types.ID
    field :customerId, types.ID
    field :status, types.String
    field :mode, types.String
    field :currencyCode, types.String,
          resolve: ->(obj, _args, _ctx) { obj.currency.code }
    field :amount, types.Float
    field :comment, types.String
    field :createdAt, types.String do
      resolve ->(obj, _args, _ctx) { obj.created_at.strftime('%e.%m.%y') }
    end
    field :updatedAt, types.String do
      resolve ->(obj, _args, _ctx) { obj.updated_at.strftime('%e.%m.%y') }
    end
  end
end
