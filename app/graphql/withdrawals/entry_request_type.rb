module Withdrawals
  EntryRequestType = GraphQL::ObjectType.define do
    name 'EntryRequest'

    field :id, types.ID
    field :status, types.String
  end
end
