module Account
  RegisterInput = GraphQL::InputObjectType.define do
    name 'RegisterInput'

    argument :username, !types.String
    argument :email, !types.String
    argument :first_name, !types.String
    argument :last_name, !types.String
    argument :date_of_birth, !types.String
    argument :password, !types.String
    argument :password_confirmation, !types.String
  end
end
