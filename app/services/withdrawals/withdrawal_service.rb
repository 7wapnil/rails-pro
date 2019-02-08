module Withdrawals
  class WithdrawalService < ApplicationService
    def initialize(wallet, amount)
      @wallet = wallet
      @amount = amount
    end

    def call
      WithdrawalVerification.call(wallet, amount)
      entry_request = WithdrawalRequestBuilder.call(wallet, amount)
      WalletEntry::AuthorizationService.call(entry_request)
    end

    private

    attr_reader :wallet, :amount
  end
end
