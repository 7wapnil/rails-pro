# frozen_string_literal: true

module EntryRequests
  class BonusChangeService < ApplicationService
    include JobLogger

    delegate :initiator, :customer, to: :entry_request

    def initialize(entry_request:)
      @entry_request = entry_request
      @customer_bonus = entry_request.origin
    end

    def call
      return charge_failed! if entry_request.failed?

      process_entry_request!

      assign_balance_entry if entry
    end

    private

    attr_reader :entry_request, :customer_bonus, :entry

    def charge_failed!
      log_job_message(:error,
                      message: 'Failed entry request passed to payment service',
                      entry_request_id: entry_request.id)

      raise FailedEntryRequestError,
            'Failed entry request passed to payment service'
    end

    def process_entry_request!
      @entry = ::WalletEntry::AuthorizationService.call(entry_request)
    end

    def assign_balance_entry
      return unless debit?

      customer_bonus.update(balance_entry: entry.bonus_balance_entry)
    end

    def debit?
      entry.amount.positive?
    end
  end
end
