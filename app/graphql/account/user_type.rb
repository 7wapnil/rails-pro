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
    field :agreed_with_promotional, !types.Boolean
    field :address_street_address, types.String
    field :address_zip_code, types.String
    field :address_country, types.String
    field :address_city, types.String
    field :address_state, types.String
    field :regular, types.Boolean do
      resolve ->(obj, _args, _ctx) { obj.regular? }
    end
    field :available_withdraw_methods, types[types.String]
  end
end
