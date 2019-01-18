module Account
  DepositRequestResponse = GraphQL::ObjectType.define do
    name 'DepositRequest'

    field :success, !types.String
    field :result, types.String
    field :url, types.String
  end
end
