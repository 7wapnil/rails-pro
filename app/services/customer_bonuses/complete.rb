module CustomerBonuses
  class Complete < ApplicationService
    delegate :wallet, to: :customer_bonus
    delegate :bonus_balance, to: :wallet

    def initialize(customer_bonus:)
      @customer_bonus = customer_bonus
    end

    def call
      return unless customer_bonus.active?

      return if customer_bonus.rollover_balance.positive?

      complete_bonus
      submit_entry_requests
    end

    attr_reader :customer_bonus

    private

    def submit_entry_requests
      subtract_request = remove_bonus_money_request
      add_request = grant_real_money_request

      EntryRequests::BonusChangeService.call(entry_request: subtract_request)
      EntryRequests::ProcessingService.call(entry_request: add_request)
    end

    def remove_bonus_money_request
      EntryRequests::Factories::BonusChange.call(
        customer_bonus: customer_bonus,
        amount: -bonus_balance.amount
      )
    end

    def grant_real_money_request
      EntryRequests::Factories::BonusConversion.call(
        customer_bonus: customer_bonus,
        amount: bonus_balance.amount
      )
    end

    def complete_bonus
      customer_bonus.complete!
    end
  end
end
