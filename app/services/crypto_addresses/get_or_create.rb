# frozen_string_literal: true

module CryptoAddresses
  class GetOrCreate < ApplicationService
    def initialize(transaction)
      @transaction = transaction
    end

    def call
      return wallet_crypto_address.address if crypto_address?

      create_crypto_address!
      crypto_address.address
    end

    private

    attr_reader :transaction, :crypto_address

    delegate :wallet, to: :transaction
    delegate :crypto_address, to: :wallet, prefix: true

    def crypto_address?
      wallet_crypto_address.present?
    end

    def create_crypto_address!
      @crypto_address =
        CryptoAddress.create(
          wallet: wallet,
          address: generate_address
        )
    end

    def generate_address
      Payments::CoinsPaid::Client
        .new
        .generate_address(transaction.customer)
    end
  end
end
