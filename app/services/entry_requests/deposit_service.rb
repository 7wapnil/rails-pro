# frozen_string_literal: true

module EntryRequests
  class DepositService < ApplicationService
    delegate :bonus_balance_entry_request, to: :entry_request

    def initialize(entry_request:)
      @entry_request = entry_request
      @wallet = entry_request.origin
      @customer_bonus = wallet.customer.customer_bonus
    end

    def call
      return if entry_request.failed?

      validate_entry_request!
      attach_entry_to_bonus!
    end

    private

    attr_reader :entry_request, :wallet, :customer_bonus, :entry

    def validate_entry_request!
      @entry = ::WalletEntry::AuthorizationService.call(entry_request)
    end

    def attach_entry_to_bonus!
      return unless bonus_balance_entry_request

      customer_bonus.update_attributes!(entry: entry)
    end
  end
end
