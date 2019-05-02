module EntryRequests
  class WithdrawalService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
    end

    def call
      authorize_entry_request!
      remove_bonus!
      authorize_entry!
    end

    private

    attr_reader :entry_request, :entry

    delegate :customer, to: :entry_request
    delegate :customer_bonus, to: :customer

    def authorize_entry_request!
      @entry = WalletEntry::AuthorizationService.call(entry_request)
    end

    def remove_bonus!
      Bonuses::Cancel.call(
        bonus: customer_bonus,
        reason: CustomerBonus::WITHDRAWAL
      )
    end

    def authorize_entry!
      entry.update_attributes!(authorized_at: Time.zone.now)
    end
  end
end
