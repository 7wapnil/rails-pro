module Account
  AccountType = GraphQL::ObjectType.define do
    name 'Account'

    field :user, !Account::UserType
    field :token, !types.String
  end
end
