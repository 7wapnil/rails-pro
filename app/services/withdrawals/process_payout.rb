# frozen_string_literal: true

module Withdrawals
  class ProcessPayout < ApplicationService
    def initialize(withdraw)
      @withdraw = withdraw
      @entry_request = withdraw.entry_request
    end

    def call
      return if request.code.to_i == 201

      withdraw.update(
        transaction_message: error_message,
        status: ::Withdrawal::PENDING
      )
      payout_failed!
    end

    private

    attr_reader :withdraw, :entry_request

    def request
      @request ||= ::Payments::Payout.call(transaction)
    end

    def transaction
      ::Payments::Transactions::Payout.new(
        id: withdraw.id,
        method: entry_request.mode,
        customer: entry_request.customer,
        currency_code: entry_request.currency.code,
        amount: -entry_request.amount.to_d,
        details: withdraw.details
      )
    end

    def error_message
      @error_message ||= JSON.parse(request.body)['errors']&.values&.first
    end

    def payout_failed!
      raise Withdrawals::PayoutError,
            "CoinsPaid: #{error_message}"
    end
  end
end
