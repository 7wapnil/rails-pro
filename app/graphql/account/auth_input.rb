module Account
  AuthInput = GraphQL::InputObjectType.define do
    name 'AuthInput'

    argument :email, !types.String
    argument :password, !types.String
  end
end
