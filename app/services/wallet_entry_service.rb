class WalletEntryService < ApplicationService
  def initialize(request_id)
    @request = EntryRequest.find(request_id)
  end

  def call
    create_entry
  end

  private

  def create_entry
    ActiveRecord::Base.transaction do
      amount = @request.payload['amount']

      @wallet = Wallet.find_or_create_by!(
        customer_id: @request.payload['customer_id'],
        currency: @request.payload['currency']
      )

      @balance = Balance.find_or_create_by!(
        wallet_id: @wallet.id,
        kind: Balance.kinds[:real_money]
      )

      @entry = Entry.create!(
        wallet_id: @wallet.id,
        kind: @request.payload['kind'],
        amount: amount
      )

      BalanceEntry.create!(
        balance_id: @balance.id,
        entry_id: @entry.id,
        amount: amount
      )

      @wallet.increment! :amount, amount
      @balance.increment! :amount, amount
    end
  end
end
