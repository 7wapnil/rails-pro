module CustomerBonuses
  class Complete < ApplicationService
    delegate :wallet, to: :customer_bonus, allow_nil: true
    delegate :bonus_balance, to: :wallet, allow_nil: true

    def initialize(customer_bonus:)
      @customer_bonus = customer_bonus
    end

    def call
      return unless customer_bonus && customer_bonus&.active?

      return if customer_bonus.rollover_balance.positive?

      complete_bonus
      submit_entry_requests
    end

    attr_reader :customer_bonus

    private

    def submit_entry_requests
      [remove_bonus_money_request, grant_real_money_request].each do |request|
        EntryRequests::BonusChangeWorker.perform_async(request.id)
      end
    end

    def remove_bonus_money_request
      EntryRequests::Factories::BonusChange.call(
        customer_bonus: customer_bonus,
        amount: -bonus_balance.amount
      )
    end

    def grant_real_money_request
      EntryRequests::Factories::Deposit.call(
        wallet: wallet,
        amount: bonus_balance.amount,
        mode: EntryRequest::INTERNAL
      )
    end

    def complete_bonus
      customer_bonus.complete!
    end
  end
end
