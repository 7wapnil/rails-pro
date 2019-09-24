# frozen_string_literal: true

module EntryRequests
  class DepositService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
      @customer_bonus = entry_request.origin&.customer_bonus
    end

    def call
      return failure if entry_request.failed?

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
      entry_request.deposit.succeeded!
      customer_bonus&.activate!(entry)
    end

    def failure
      entry_request.deposit.failed!
      customer_bonus&.fail!

      raise ::Payments::FailedError
    end
  end
end
