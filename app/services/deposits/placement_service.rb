module Deposits
  class PlacementService < ApplicationService
    ENTRY_REQUEST_KIND = EntryRequest.kinds[:deposit]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:cashier]

    def initialize(wallet, amount, initiator = nil)
      @wallet = wallet
      @amount = amount
      @initiator = initiator || wallet.customer
      @customer_bonus = wallet.customer.customer_bonus
    end

    def call
      validate_deposit_placement!
      close_customer_bonus! if customer_bonus&.expired?
      entry = WalletEntry::AuthorizationService.call(entry_request)
      attach_source_to_customer_bonus!(entry) if entry
    end

    private

    attr_reader :wallet, :amount, :initiator, :customer_bonus

    def balances_amounts
      @balances_amounts ||= begin
        amounts = BalanceCalculations::Deposit.call(customer_bonus, amount)
        amounts[:bonus] = 0 unless eligible_for_the_bonus?
        amounts
      end
    end

    def entry_request
      @entry_request ||= begin
        request = EntryRequest.create!(
          customer_id: wallet.customer_id,
          currency_id: wallet.currency_id,
          kind: ENTRY_REQUEST_KIND,
          mode: ENTRY_REQUEST_MODE,
          amount: amount,
          initiator: initiator
        )
        BalanceRequestBuilders::Deposit.call(request, balances_amounts)
        request
      end
    end

    def validate_deposit_placement!
      # TODO : implement validation logic
      deposit_limit = DepositLimit.find_by(customer: wallet.customer,
                                           currency: wallet.currency)

      raise 'Customer has a deposit limit.' if deposit_limit
    end

    def eligible_for_the_bonus?
      return false if customer_bonus&.source || customer_bonus&.min_deposit.nil?

      customer_bonus.unexpired? && amount >= customer_bonus.min_deposit
    end

    def close_customer_bonus!
      customer_bonus.close!(BonusExpiration::Expired, reason: :expired_by_date)
    end

    def attach_source_to_customer_bonus!(entry)
      return unless eligible_for_the_bonus?

      customer_bonus.update_attributes!(source: entry)
    end
  end
end
