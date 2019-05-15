module Deposits
  class DepositLimitCheckService < ApplicationService
    def initialize(customer, amount, currency)
      @customer = customer
      @amount = amount.to_d
      @currency = currency
    end

    def call
      return true if available_deposit_limit?

      raise Deposits::DepositLimitRestrictionError,
            I18n.t('errors.messages.deposit_limit_exceeded')
    end

    private

    def available_deposit_limit?
      return true unless deposit_limits

      potential_new_deposits_total < deposit_limits.value
    end

    def potential_new_deposits_total
      existing_deposits_volume + @amount
    end

    def deposit_limits
      @deposit_limits ||= @customer.deposit_limits.find_by(currency: @currency)
    end

    def existing_deposits_volume
      @customer
        .entry_requests
        .where(
          status: [EntryRequest::PENDING, EntryRequest::SUCCEEDED],
          kind: EntryRequest::DEPOSIT,
          created_at: (deposit_limits.range.days.ago...Time.current)
        )
        .sum(:amount)
    end
  end
end
