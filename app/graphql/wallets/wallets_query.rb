module Wallets
  class WalletsQuery < ::Base::Resolver
    type !types[WalletType]
    mark_as_trackable

    def resolve(_obj, _args)
      wallets = Wallet.where(customer: @current_customer).all
      return wallets unless wallets.empty?

      Array.new(1) { Wallet.build_default }
    end
  end
end
