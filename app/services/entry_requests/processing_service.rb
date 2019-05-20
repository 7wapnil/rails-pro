# frozen_string_literal: true

module EntryRequests
  class ProcessingService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
    end

    def call
      authorize_entry_request!
    end

    private

    attr_reader :entry_request, :entry

    def authorize_entry_request!
      WalletEntry::AuthorizationService.call(entry_request)
    end
  end
end
