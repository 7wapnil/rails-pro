module Withdrawals
  class InitiateWithdrawalService < ApplicationService
    def initialize(wallet:, amount:, mode: EntryRequest::CASHIER, **attrs)
      @wallet = wallet
      @amount = amount
      @mode = mode
      @attrs = attrs
    end

    def call
      WithdrawalVerification.call(wallet, amount)
      EntryRequests::Factories::Withdraw.call(wallet: wallet,
                                              amount: amount,
                                              mode: mode,
                                              **attrs)
    end

    private

    attr_reader :wallet, :amount, :mode, :attrs
  end
end
