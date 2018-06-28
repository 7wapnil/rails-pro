module Account
  AuthInput = GraphQL::InputObjectType.define do
    name 'AuthInput'

    argument :username, !types.String
    argument :password, !types.String
  end
end
