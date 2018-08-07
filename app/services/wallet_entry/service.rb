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
    rescue ActiveRecord::RecordInvalid => e
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

    def create_entry! # rubocop:disable Metrics/MethodLength
      @entry = Entry.create!(
        wallet_id: @wallet.id,
        origin: @request.origin,
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

      @wallet.update_attributes!(amount: @wallet.amount + @amount)
    end

    def update_balance!
      @balance = Balance.find_or_create_by!(
        wallet_id: @wallet.id,
        kind: Balance.kinds[:real_money]
      )

      @balance.update_attributes!(amount: @balance.amount + @amount)
    end

    def handle_success
      @request.succeeded!
      @entry
    end

    def handle_failure(exception)
      @request.update_columns(
        status: EntryRequest.statuses[:failed],
        result: {
          message: exception,
          exception_class: exception.class.to_s
        }
      )
      nil
    end
  end
end
