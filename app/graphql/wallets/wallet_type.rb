module Wallets
  WalletType = GraphQL::ObjectType.define do
    name 'Wallet'

    field :id, types.ID
    field :amount, !types.Float
    field :realMoneyBalance, !types.Float, property: :real_money_balance
    field :bonusBalance, !types.Float, property: :bonus_balance

    field :currency, Currencies::CurrencyType
  end
end
