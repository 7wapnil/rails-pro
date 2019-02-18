module Withdrawals
  class WithdrawalRequestBuilder < ApplicationService
    def initialize(wallet, amount, **options)
      @wallet = wallet
      @amount = amount
      @mode = options[:mode]
    end

    def call
      build_entry_request!
    end

    private

    attr_reader :wallet, :amount, :mode

    def build_entry_request!
      EntryRequest.create!(
        kind: EntryRequest::WITHDRAW,
        currency: wallet.currency,
        customer: wallet.customer,
        amount: amount,
        initiator: wallet.customer,
        mode: mode
      )
    end
  end
end
