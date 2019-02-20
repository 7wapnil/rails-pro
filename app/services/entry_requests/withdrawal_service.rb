module EntryRequests
  class WithdrawalService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
    end

    def call
      authorize_entry_request!
      authorize_entry!
    end

    private

    attr_reader :entry_request, :entry

    def authorize_entry_request!
      @entry = WalletEntry::AuthorizationService.call(entry_request)
    end

    def authorize_entry!
      entry.update_attributes!(authorized_at: Time.zone.now)
    end
  end
end
