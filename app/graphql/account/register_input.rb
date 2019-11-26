module Account
  RegisterInput = GraphQL::InputObjectType.define do
    name 'RegisterInput'

    argument :username, !types.String
    argument :email, !types.String
    argument :dateOfBirth, !types.String
    argument :password, !types.String
    argument :country, !types.String
    argument :agreedWithPromotional, !types.Boolean
    argument :agreedWithPrivacy, !types.Boolean
    argument :currency, !types.String
    argument :bTag, types.String
  end
end
