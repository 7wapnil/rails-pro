# frozen_string_literal: true

module Withdrawals
  class ProcessPayout < ApplicationService
    delegate :entry, to: :withdrawal

    def initialize(withdrawal)
      @withdrawal = withdrawal
      @entry_request = withdrawal.entry_request
      @confirmed_at = Time.zone.now
    end

    def call
      payout!
      confirm_entry
    end

    private

    attr_reader :withdrawal, :entry_request, :confirmed_at

    def payout!
      ::Payments::Payout.call(transaction)
    end

    def transaction
      ::Payments::Transactions::Payout.new(
        id: entry_request.id,
        method: entry_request.mode,
        customer: entry_request.customer,
        currency_code: entry_request.currency.code,
        amount: entry_request.amount.abs.to_d,
        withdrawal: withdrawal,
        details: withdrawal.details
      )
    end

    def confirm_entry
      entry.update!(confirmed_at: confirmed_at)
    end
  end
end
