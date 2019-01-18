module Account
  DepositRequestInput = GraphQL::InputObjectType.define do
    name 'DepositRequestInput'

    argument :amount, !types.String
    argument :currency_code, !types.String
    argument :bonus_code, types.String
  end
end
