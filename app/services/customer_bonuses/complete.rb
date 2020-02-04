module CustomerBonuses
  class Complete < ApplicationService
    delegate :wallet, to: :customer_bonus
    delegate :bonus_balance, to: :wallet

    def initialize(customer_bonus:)
      @customer_bonus = customer_bonus
    end

    def call
      return unless eligible?

      ActiveRecord::Base.transaction do
        complete_bonus!
        remove_bonus_money!
        grant_real_money!
      end
    end

    attr_reader :customer_bonus

    private

    def eligible?
      return false unless customer_bonus.active?

      customer_bonus.rollover_balance <= 0
    end

    def complete_bonus!
      customer_bonus.complete!(bonus_balance)
    end

    def remove_bonus_money!
      EntryRequests::BonusChangeService
        .call(entry_request: remove_bonus_money_request)
    end

    def grant_real_money!
      EntryRequests::BonusChangeService
        .call(entry_request: grant_real_money_request)
    end

    def remove_bonus_money_request
      EntryRequests::Factories::BonusChange.call(
        customer_bonus: customer_bonus,
        amount: -bonus_balance
      )
    end

    def grant_real_money_request
      EntryRequests::Factories::BonusConversion.call(
        customer_bonus: customer_bonus,
        amount: bonus_balance
      )
    end
  end
end
