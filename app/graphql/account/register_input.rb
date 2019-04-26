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
    argument :country, !types.String
    argument :city, !types.String
    argument :street_address, !types.String
    argument :state, !types.String
    argument :zip_code, !types.String
    argument :gender, !types.String
    argument :phone, !types.String
    argument :agreed_with_promotional, !types.Boolean
    argument :b_tag, types.String
  end
end
