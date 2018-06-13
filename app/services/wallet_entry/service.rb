module WalletEntry
  class Service < ApplicationService
    def initialize(request)
      @request = request
      @amount = @request.amount
    end

    def call
      @request.validate!
      update_database!
      handle_success
    rescue ActiveModel::ValidationError => e
      handle_failure e
    end

    private

    def update_database!
      ActiveRecord::Base.transaction do
        update_wallet!
        update_balance!
        create_entry!
      end
    end

    def create_entry!
      @entry = Entry.create!(
        wallet_id: @wallet.id,
        kind: @request.kind,
        amount: @amount
      )

      BalanceEntry.create!(
        balance_id: @balance.id,
        entry_id: @entry.id,
        amount: @amount
      )
    end

    def update_wallet!
      @wallet = Wallet.find_or_create_by!(
        customer: @request.customer,
        currency: @request.currency
      )

      @wallet.increment! :amount, @amount
    end

    def update_balance!
      @balance = Balance.find_or_create_by!(
        wallet_id: @wallet.id,
        kind: Balance.kinds[:real_money]
      )
      @balance.increment! :amount, @amount
    end

    def handle_success
      @request.success!
    end

    def handle_failure(exception)
      @request.update_columns(
        status: EntryRequest.statuses[:fail],
        result: {
          message: exception,
          exception_class: exception.class.to_s
        }
      )
    end
  end
end
