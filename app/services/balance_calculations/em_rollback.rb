# frozen_string_literal: true

module BalanceCalculations
  class EmRollback < ApplicationService
    MONEY_PRECISION = 2
    REAL_MONEY_ONLY_RATIO = 1.0

    delegate :wallet, to: :rollback
    delegate :real_money_balance, :bonus_balance, to: :wallet, allow_nil: true

    def initialize(rollback:)
      @rollback = rollback
    end

    def call
      {
        real_money_amount: calculated_real_money_amount,
        bonus_amount: calculated_bonus_amount
      }
    end

    private

    attr_reader :rollback

    def calculated_real_money_amount
      @calculated_real_money_amount ||= (rollback.amount * ratio)
                                        .round(MONEY_PRECISION)
    end

    def ratio
      REAL_MONEY_ONLY_RATIO
    end

    def calculated_bonus_amount
      rollback.amount - calculated_real_money_amount
    end
  end
end
