module Withdrawals
  WithdrawalResultType = GraphQL::ObjectType.define do
    name 'WithdrawalResult'

    field :id, types.ID
    field :status, types.String
    field :amount, types.Float
    field :kind, types.String
    field :mode, types.String
    field :customerId, types.ID
    field :currencyId, types.ID
    field :initiatorId, types.ID
    field :initiatorType, types.String
    field :errorMessages, types[types.String]
  end
end
