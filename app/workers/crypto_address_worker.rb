# frozen_string_literal: true

class CryptoAddressWorker < ApplicationWorker
  def perform(wallet_id)
    @crypto_address =
      CryptoAddress.create(
        wallet: find_wallet(wallet_id),
        address:
          Payments::CoinsPaid::Client
            .new
            .generate_address(wallet.customer)
      )
  end

  private

  attr_reader :wallet

  def find_wallet(wallet_id)
    @wallet = Wallet.find(wallet_id)
  end
end
