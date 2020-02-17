# frozen_string_literal: true

module WalletEntry
  class PostAuthorizationService < ApplicationService
    delegate :customer, to: :entry

    def initialize(entry)
      @entry = entry
    end

    def call
      update_summary! unless entry.bet?
      verify_balance!
    end

    private

    attr_reader :entry

    def update_summary!
      Customers::Summaries::UpdateBalance.call(day: Date.current, entry: entry)
    end

    def verify_balance!
      Wallets::BalanceVerification.call(customer)
    end
  end
end
