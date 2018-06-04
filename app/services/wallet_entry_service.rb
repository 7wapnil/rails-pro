class WalletEntryService < ApplicationService
  def initialize(request_id)
    @request = EntryRequest.find(request_id)
  end

  def call
    ActiveRecord::Base.transaction do
      @wallet = Wallet.find_or_create_by!(
        customer_id: @request.payload['customer_id'],
        currency: @request.payload['currency']
      )

      @balance = Balance.find_or_create_by!(
        wallet_id: @wallet.id,
        kind: Balance.kinds[:real_money]
      )
    end
  end
end
