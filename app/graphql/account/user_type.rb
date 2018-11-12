module Account
  UserType = GraphQL::ObjectType.define do
    name 'User'

    field :id, !types.ID
    field :email, !types.String
    field :username, !types.String
    field :verified, !types.Boolean
    field :date_of_birth, !types.String
    field :phone, types.String
    field :gender, types.String
    field :first_name, !types.String
    field :last_name, !types.String
    field :address_street_address, types.String
    field :address_zip_code, types.String
    field :address_country, types.String
    field :address_city, types.String
    field :address_state, types.String
  end
end
