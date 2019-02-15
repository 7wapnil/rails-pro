module Withdrawals
  class InitiateWithdrawalService < ApplicationService
    def initialize(wallet:, amount:, mode: EntryRequest::CASHIER)
      @wallet = wallet
      @amount = amount
      @mode = mode
    end

    def call
      WithdrawalVerification.call(wallet, amount)
      EntryRequests::Factories::Withdraw.call(wallet: wallet,
                                              amount: amount,
                                              mode: mode)
    end

    private

    attr_reader :wallet, :amount, :mode
  end
end
