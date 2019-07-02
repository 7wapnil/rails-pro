module CustomerBonuses
  class Complete < ApplicationService
    delegate :wallet, to: :customer_bonus, allow_nil: true
    delegate :bonus_balance, to: :wallet, allow_nil: true

    def initialize(customer_bonus_id)
      @customer_bonus_id = customer_bonus_id
    end

    def call
      return unless customer_bonus&.active?

      return if customer_bonus.rollover_balance.positive?

      complete_bonus
      submit_entry_requests
    end

    def customer_bonus
      @customer_bonus ||= CustomerBonus.find_by(id: @customer_bonus_id)
    end

    private

    def submit_entry_requests
      request = remove_bonus_money_request
      EntryRequests::BonusChangeWorker.perform_async(request.id)

      request = grant_real_money_request
      EntryRequests::BonusConversionWorker.perform_async(request.id)
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
        amount: customer_bonus.wallet.bonus_balance.amount
      )
    end

    def complete_bonus
      customer_bonus.complete!
    end
  end
end
