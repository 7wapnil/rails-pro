# frozen_string_literal: true

module EntryRequests
  class DepositService < ApplicationService
    delegate :bonus_balance_entry_request, to: :entry_request

    def initialize(entry_request:)
      @entry_request = entry_request
      @customer_bonus = entry_request.origin&.customer_bonus
    end

    def call
      return if entry_request.failed?

      process_entry_request!

      return success if entry

      failure
    end

    private

    attr_reader :entry_request, :customer_bonus, :entry

    def process_entry_request!
      @entry = ::WalletEntry::AuthorizationService.call(entry_request)
    end

    def success
      # TODO: REFACTOR AFTER CUSTOMER BONUS IMPLEMENTATION
      customer_bonus&.active! if customer_bonus
    end

    def failure
      # TODO: REFACTOR AFTER CUSTOMER BONUS IMPLEMENTATION
      customer_bonus&.failed! if customer_bonus
    end
  end
end
