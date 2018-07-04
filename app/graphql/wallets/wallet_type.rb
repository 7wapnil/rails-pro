module Wallets
  WalletType = GraphQL::ObjectType.define do
    name 'Wallet'

    field :id, types.ID
    field :amount, !types.Float

    field :currency, CurrencyType
  end
end