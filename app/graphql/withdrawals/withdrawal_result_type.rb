module Withdrawals
  WithdrawalResultType = GraphQL::ObjectType.define do
    name 'WithdrawalResult'

    field :entryRequest, EntryRequestType
    field :error, types.String
  end
end
