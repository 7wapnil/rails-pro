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

    def create_entry!
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
      log_success

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
      log_failure

      nil
    end

    def log_success
      Audit::Service.call(
        event: :entry_created,
        origin_kind: @request.initiator_type,
        origin_id: @request.initiator_id,
        context: @entry.loggable_attributes.merge(
          target_class: :customer,
          target_id: @request.customer_id
        )
      )
    end

    def log_failure
      Audit::Service.call(
        event: :entry_creation_failed,
        origin_kind: @request.initiator_type,
        origin_id: @request.initiator_id,
        context: @request.loggable_attributes.merge(
          target_class: :customer,
          target_id: @request.customer_id
        )
      )
    end
  end
end
