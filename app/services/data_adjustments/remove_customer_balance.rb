module DataAdjustments
  class RemoveCustomerBalance < ApplicationService
    attr_reader :customer

    def initialize(customer_id)
      @customer = Customer.includes(:wallets).find(customer_id)
    end

    def call # rubocop:disable Metrics/MethodLength
      customer.wallets.each do |wallet|
        next unless wallet.with_money?

        request = EntryRequest.create!(
          kind: EntryRequest::SYSTEM_ADJUSTMENT,
          mode: :cashier,
          comment: 'Removing player balance that occured by a system error',
          customer: customer,
          currency: wallet.currency,
          amount: -wallet.amount,
          real_money_amount: -wallet.real_money_balance,
          bonus_amount: -wallet.bonus_balance,
          confiscated_bonus_amount: -wallet.confiscated_bonus_balance
        )

        entry = WalletEntry::AuthorizationService.call(request)

        entry.confirm!
      end
    end
  end
end
