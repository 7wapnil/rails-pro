module Deposits
  class PlacementService < ApplicationService
    ENTRY_REQUEST_KIND = EntryRequest.kinds[:deposit]
    ENTRY_REQUEST_MODE = EntryRequest.modes[:cashier]

    def initialize(wallet, amount, initiator = nil)
      @wallet = wallet
      @amount = amount
      @initiator = initiator || wallet.customer
    end

    def call
      validate_deposit_placement!
      ActiveRecord::Base.transaction do
        authorize_real_money!
        authorize_bonus_money!
      end
    end

    private

    attr_reader :wallet, :amount, :initiator

    def authorize_real_money!
      real_money_entry_request.save!
      WalletEntry::AuthorizationService.call(real_money_entry_request,
                                             :real_money)
    end

    def authorize_bonus_money!
      return if balances_amounts[:bonus].blank? || !eligible_for_the_bonus?

      bonus_entry_request.save!
      WalletEntry::AuthorizationService.call(bonus_entry_request,
                                             :bonus)
    end

    def bonus_entry_request
      @bonus_entry_request ||= EntryRequest.new(
        base_attrs.merge(amount: balances_amounts[:bonus])
      )
    end

    def balances_amounts
      @balances_amounts ||= BalanceCalculations::Deposit.call(wallet,
                                                              amount)
    end

    def real_money_entry_request
      @real_money_entry_request ||= EntryRequest.new(
        base_attrs.merge(amount: balances_amounts[:real_money])
      )
    end

    def base_attrs
      {
        customer_id: wallet.customer_id,
        currency_id: wallet.currency_id,
        kind: ENTRY_REQUEST_KIND,
        mode: ENTRY_REQUEST_MODE,
        initiator: initiator
      }
    end

    def validate_deposit_placement!
      # TODO : implement validation logic
      deposit_limit = DepositLimit.find_by(customer: wallet.customer,
                                           currency: wallet.currency)

      raise 'Customer has a deposit limit.' if deposit_limit
    end

    def eligible_for_the_bonus?
      min_deposit = wallet.customer&.customer_bonus&.min_deposit
      return true unless min_deposit

      amount >= min_deposit
    end
  end
end
