module EntryRequests
  class DepositService < ApplicationService
    def initialize(entry_request:, amount:)
      @entry_request = entry_request
      @amount = amount
      @wallet = entry_request.origin
      @customer_bonus = wallet.customer.customer_bonus
    end

    def call
      validate_deposit_placement!
      close_customer_bonus! if customer_bonus&.expired?

      validate_entry_request!
      attach_entry_to_bonus! if entry
    end

    private

    attr_reader :entry_request, :wallet, :amount, :customer_bonus, :entry

    def validate_deposit_placement!
      # TODO : implement validation logic
      deposit_limit = DepositLimit.find_by(customer: wallet.customer,
                                           currency: wallet.currency)

      raise 'Customer has a deposit limit.' if deposit_limit
    end

    def close_customer_bonus!
      customer_bonus.close!(BonusExpiration::Expired, reason: :expired_by_date)
    end

    def validate_entry_request!
      @entry = ::WalletEntry::AuthorizationService.call(entry_request)
    end

    def attach_entry_to_bonus!
      return unless customer_bonus&.eligible_with?(amount)

      customer_bonus.update_attributes!(entry: entry)
    end
  end
end
