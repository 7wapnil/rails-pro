module Withdrawals
  class WithdrawalVerification < ApplicationService
    NOT_ENOUGH_MONEY = I18n.t('errors.messages.withdrawal.not_enouh_money')
    ACTIVE_BONUS_EXISTS = I18n.t('errors.messages.withdrawal.bonus_exists')

    def initialize(wallet, amount)
      @wallet = wallet
      @amount = amount
    end

    def call
      verify_business_rules!
    end

    private

    attr_reader :wallet, :amount

    def verify_business_rules!
      verify_bonus_existence!
      verify_amount!
    end

    def verify_amount!
      return if amount <= wallet.real_money_balance.amount

      register_failure! NOT_ENOUGH_MONEY
    end

    def verify_bonus_existence!
      register_failure! ACTIVE_BONUS_EXISTS if wallet.customer.active_bonus
    end

    def register_failure!(msg)
      raise WithdrawalError, msg
    end
  end
end
