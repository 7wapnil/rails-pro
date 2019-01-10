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
      calculations = { real_money: balances_amounts[:real_money],
                       bonus: balances_amounts[:bonus] }
      # TODO: clarify with team, pass 0 to avoid balance request creation
      calculations[:bonus] = 0 unless eligible_for_the_bonus?
      validate_deposit_placement!
      request = build_entry_request
      request.save!
      BalanceRequestBuilders::Deposit.call(request, calculations)
      WalletEntry::AuthorizationService.call(request)
    end

    private

    attr_reader :wallet, :amount, :initiator, :customer_bonus

    def bonus_entry_request
      @bonus_entry_request ||= EntryRequest.new(
        base_attrs.merge(amount: balances_amounts[:bonus],
                         mode: EntryRequest.modes[:system])
      )
    end

    def balances_amounts
      @balances_amounts ||= BalanceCalculations::Deposit.call(customer_bonus,
                                                              amount)
    end

    def build_entry_request
      EntryRequest.new(
        customer_id: wallet.customer_id,
        currency_id: wallet.currency_id,
        kind: ENTRY_REQUEST_KIND,
        mode: ENTRY_REQUEST_MODE,
        amount: amount,
        initiator: initiator
      )
    end

    def validate_deposit_placement!
      # TODO : implement validation logic
      deposit_limit = DepositLimit.find_by(customer: wallet.customer,
                                           currency: wallet.currency)

      raise 'Customer has a deposit limit.' if deposit_limit
    end

    def eligible_for_the_bonus?
      customer_bonus = wallet.customer&.customer_bonus
      return false unless customer_bonus&.min_deposit

      if customer_bonus.expired?
        customer_bonus.close!(BonusExpiration::Expired,
                              reason: :expired_by_date)
        return false
      end
      amount >= customer_bonus.min_deposit
    end
  end
end
