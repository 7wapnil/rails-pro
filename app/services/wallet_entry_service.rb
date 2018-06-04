class WalletEntryService < ApplicationService
  def initialize(request_id)
    @request = EntryRequest.find(request_id)
    @amount = @request.payload['amount']
  end

  def call
    update_database
  end

  private

  def update_database
    ActiveRecord::Base.transaction do
      update_wallet
      update_balance
      create_entry
    end
  end

  def create_entry
    @entry = Entry.create!(
      wallet_id: @wallet.id,
      kind: @request.payload['kind'],
      amount: @amount
    )

    BalanceEntry.create!(
      balance_id: @balance.id,
      entry_id: @entry.id,
      amount: @amount
    )
  end

  def update_wallet
    @wallet = Wallet.find_or_create_by!(
      customer_id: @request.payload['customer_id'],
      currency: @request.payload['currency']
    )
    @wallet.increment! :amount, @amount
  end

  def update_balance
    @balance = Balance.find_or_create_by!(
      wallet_id: @wallet.id,
      kind: Balance.kinds[:real_money]
    )
    @balance.increment! :amount, amount
  end
end
