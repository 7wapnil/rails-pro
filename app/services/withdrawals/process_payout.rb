# frozen_string_literal: true

module Withdrawals
  class ProcessPayout < ApplicationService
    def initialize(withdrawal)
      @withdrawal = withdrawal
      @entry_request = withdrawal.entry_request
    end

    def call
      ::Payments::Payout.call(transaction)
    end

    private

    attr_reader :withdrawal, :entry_request

    def transaction
      ::Payments::Transactions::Payout.new(
        id: entry_request.id,
        method: entry_request.mode,
        customer: entry_request.customer,
        currency_code: entry_request.currency.code,
        amount: -entry_request.amount.to_d,
        withdrawal: withdrawal,
        details: withdrawal.details
      )
    end
  end
end
