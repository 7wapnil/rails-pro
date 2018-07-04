module Wallets
  class WalletsQuery < ::Base::Resolver
    type !types[WalletType]

    def call(_obj, _args, ctx)
      check_auth ctx

      wallets = Wallet.where(customer: ctx[:current_customer]).all
      return wallets unless wallets.empty?

      Array.new(1) { Wallet.build_default }
    end
  end
end
