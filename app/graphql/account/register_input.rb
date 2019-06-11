module Account
  RegisterInput = GraphQL::InputObjectType.define do
    name 'RegisterInput'

    argument :username, !types.String
    argument :email, !types.String
    argument :firstName, !types.String
    argument :lastName, !types.String
    argument :dateOfBirth, !types.String
    argument :password, !types.String
    argument :passwordConfirmation, !types.String
    argument :country, !types.String
    argument :city, !types.String
    argument :streetAddress, !types.String
    argument :state, !types.String
    argument :zipCode, !types.String
    argument :gender, !types.String
    argument :phone, !types.String
    argument :agreedWithPromotional, !types.Boolean
    argument :agreedWithPrivacy, !types.Boolean
    argument :currency, !types.String
    argument :bTag, types.String
  end
end
