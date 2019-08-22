# frozen_string_literal: true

module EntryRequests
  class ProcessingService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
    end

    def call
      return if entry_request.failed?

      WalletEntry::AuthorizationService.call(entry_request)
    end

    private

    attr_reader :entry_request
  end
end
