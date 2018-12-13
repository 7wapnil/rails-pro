module WalletEntry
  class AuthorizationService < ApplicationService
    def initialize(request, balance_kind = nil, in_transaction = true)
      @request = request
      @amount = @request.amount
      @balance_kind = balance_kind || Balance.kinds[:real_money]
      @in_transaction = in_transaction
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
      operations = -> do
        update_wallet!
        update_balance!
        create_entry!
      end

      if @in_transaction
        ActiveRecord::Base.transaction do
          operations.call
        end
      else
        operations.call
      end
    end

    def create_entry!
      @entry = Entry.create!(
        wallet_id: @wallet.id,
        origin: @request.origin,
        kind: @request.kind,
        amount: @amount,
        authorized_at: Time.zone.now
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
        kind: @balance_kind
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
        event: :entry_request_created,
        user: @request.customer_initiated? ? nil : @request.initiator,
        customer: @request.customer,
        context: @request
      )
    end

    def log_failure
      Audit::Service.call(
        event: :entry_creation_failed,
        user: @request.customer_initiated? ? nil : @request.initiator,
        customer: @request.customer,
        context: @request
      )
    end
  end
end
