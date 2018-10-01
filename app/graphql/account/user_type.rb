module Account
  UserType = GraphQL::ObjectType.define do
    name 'User'

    field :id, !types.ID
    field :email, !types.String
    field :username, !types.String
    field :verified, !types.Boolean
  end
end
