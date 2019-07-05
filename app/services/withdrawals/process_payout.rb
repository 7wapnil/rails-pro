# frozen_string_literal: true

module Withdrawals
  class ProcessPayout < ApplicationService
    def initialize(withdraw)
      @withdraw = withdraw
      @entry_request = withdraw.entry_request
    end

    def call
      ::Payments::Payout.call(transaction)
    end

    private

    attr_reader :withdraw, :entry_request

    def transaction
      ::Payments::Transactions::Payout.new(
        id: entry_request.id,
        method: entry_request.mode,
        customer: entry_request.customer,
        currency_code: entry_request.currency.code,
        amount: -entry_request.amount.to_d,
        details: withdraw.details
      )
    end
  end
end
