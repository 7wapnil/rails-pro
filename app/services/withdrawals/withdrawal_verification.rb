module Withdrawals
  class WithdrawalVerification < ApplicationService
    NOT_ENOUGH_MONEY = I18n.t('errors.messages.withdrawal.not_enough_money')

    def initialize(wallet, amount)
      @wallet = wallet
      @amount = amount.abs
    end

    def call
      verify_business_rules!
    end

    private

    attr_reader :wallet, :amount

    def verify_business_rules!
      verify_amount!
    end

    def verify_amount!
      return if amount <= wallet.real_money_balance.amount

      register_failure! NOT_ENOUGH_MONEY
    end

    def register_failure!(msg)
      raise WithdrawalError, msg
    end
  end
end
