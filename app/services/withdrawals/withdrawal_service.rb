module Withdrawals
  class WithdrawalService < ApplicationService
    def initialize(wallet, amount, mode = EntryRequest::CASHIER)
      @wallet = wallet
      @amount = amount
      @mode = mode
    end

    def call
      WithdrawalVerification.call(wallet, amount)
      entry_request = WithdrawalRequestBuilder.call(wallet, amount, mode: mode)
      WalletEntry::AuthorizationService.call(entry_request)
      entry_request
    end

    private

    attr_reader :wallet, :amount, :mode
  end
end
