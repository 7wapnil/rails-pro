module Account
  UserType = GraphQL::ObjectType.define do
    name 'User'

    field :id, !types.ID
    field :email, !types.String
    field :username, !types.String
    field :verified, !types.Boolean
    field :dateOfBirth, !types.String,
          property: :date_of_birth
    field :phone, types.String
    field :gender, types.String
    field :firstName, !types.String,
          property: :first_name
    field :lastName, !types.String,
          property: :last_name
    field :agreedWithPromotional, !types.Boolean,
          property: :agreed_with_promotional
    field :agreedWithPrivacy, !types.Boolean,
          property: :agreed_with_privacy
    field :addressStreetAddress, types.String,
          property: :address_street_address
    field :addressZipCode, types.String,
          property: :address_zip_code
    field :addressCountry, types.String,
          property: :address_country
    field :addressCity, types.String,
          property: :address_city
    field :addressState, types.String,
          property: :address_state
    field :regular, types.Boolean,
          property: :regular?
    field :availableWithdrawalMethods,
          types[::Payments::Withdrawals::PaymentMethodType],
          property: :available_withdrawal_methods
    field :wallets, types[::Wallets::WalletType]
  end
end
