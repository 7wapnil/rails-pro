module Account
  AuthInput = GraphQL::InputObjectType.define do
    name 'AuthInput'

    argument :login, !types.String
    argument :password, !types.String
    argument :captcha, types.String
  end
end
