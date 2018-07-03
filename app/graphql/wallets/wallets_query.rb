module Wallets
  class WalletsQuery < ::Base::Resolver
    type !types[WalletType]

    def call(_obj, _args, ctx)
      check_auth ctx

      Wallet.where(customer: ctx[:current_customer]).all
    end
  end
end
