module Withdrawals
  class WithdrawalRequestBuilder < ApplicationService
    def initialize(wallet, amount)
      @wallet = wallet
      @amount = amount
    end

    def call
      build_entry_request!
    end

    private

    attr_reader :wallet, :amount

    def build_entry_request!
      EntryRequest.create!(
        kind: EntryRequest::WITHDRAW,
        currency: wallet.currency,
        customer: wallet.customer,
        amount: amount,
        initiator: wallet.customer,
        mode: EntryRequest::CASHIER
      )
    end
  end
end
