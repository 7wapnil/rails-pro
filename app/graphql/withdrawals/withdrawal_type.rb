module Withdrawals
  WithdrawalType = GraphQL::ObjectType.define do
    name 'Withdrawal'

    field :id, !types.ID
    field :customer_id, types.ID
    field :status, types.String
    field :mode, types.String
    field :currencyCode, types.String,
          resolve: ->(obj, _args, _ctx) { obj.currency.code }
    field :amount, types.Float
    field :comment, types.String
  end
end
