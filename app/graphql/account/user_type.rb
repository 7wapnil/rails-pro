module Account
  UserType = GraphQL::ObjectType.define do
    name 'User'

    field :id, !types.ID
    field :email, !types.String
    field :username, !types.String
    field :verified, !types.Boolean
    field :dateOfBirth, !types.String,
          property: :date_of_birth
    field :phone, types.String do
      resolve ->(obj, *) { obj.phone && "+#{obj.phone}" }
    end
    field :gender, types.String
    field :firstName, types.String,
          property: :first_name
    field :lastName, types.String,
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
    field :needMoreInfo, types.Boolean do
      resolve ->(obj, _args, _ctx) do
        Customer::ADDRESS_INFO_FIELDS.any? { |attr| obj.address[attr].nil? } ||
          Customer::DEPOSIT_INFO_FIELDS.any? { |attr| obj[attr].nil? }
      end
    end
  end
end
