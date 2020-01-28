# frozen_string_literal: true

module EntryRequests
  class BonusChangeService < ApplicationService
    include JobLogger

    def initialize(entry_request:)
      @entry_request = entry_request
    end

    def call
      return charge_failed! unless eligible?

      authorize!
      return charge_failed! unless entry.present?

      entry
    end

    private

    attr_reader :entry_request, :entry

    def eligible?
      !entry_request.failed? && entry_request.entry.blank?
    end

    def authorize!
      @entry = ::WalletEntry::AuthorizationService.call(entry_request)
    end

    def charge_failed!
      raise FailedEntryRequestError,
            I18n.t('errors.messages.bonuses.failed_authorization')
    rescue FailedEntryRequestError => e
      log_job_message(:error,
                      message: e.message,
                      error_object: e,
                      entry_request_id: entry_request.id)

      raise e
    end
  end
end
