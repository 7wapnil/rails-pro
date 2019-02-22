module Withdrawals
  WithdrawalResultType = GraphQL::ObjectType.define do
    name 'WithdrawalResult'

    field :id, types.ID
    field :status, types.String
    field :amount, types.Float
    field :kind, types.String
    field :mode, types.String
    field :customer_id, types.ID
    field :currency_id, types.ID
    field :initiator_id, types.ID
    field :initiator_type, types.String
    field :error_messages, types[types.String]
  end
end
