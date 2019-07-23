# frozen_string_literal: true

class CryptoAddressWorker < ApplicationWorker
  def perform(wallet_id)
    @crypto_address =
      CryptoAddress.create(
        wallet: find_wallet(wallet_id),
        address: generate_address
      )
  end

  private

  attr_reader :wallet

  def find_wallet(wallet_id)
    @wallet = Wallet.find(wallet_id)
  end

  def generate_address
    Payments::Crypto::CoinsPaid::Client
      .new
      .generate_address(wallet.customer)
  end
end
