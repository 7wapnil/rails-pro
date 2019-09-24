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

      assign_entry if entry
    end

    private

    attr_reader :entry_request, :customer_bonus, :entry

    def charge_failed!
      raise FailedEntryRequestError,
            'Failed entry request passed to payment service'
    rescue FailedEntryRequestError => e
      log_job_message(:error,
                      message: e.message,
                      error_object: e,
                      entry_request_id: entry_request.id)

      raise e
    end

    def process_entry_request!
      @entry = ::WalletEntry::AuthorizationService.call(entry_request)
    end

    def assign_entry
      return unless debit?

      customer_bonus.update(entry: entry)
    end

    def debit?
      entry.amount.positive?
    end
  end
end
