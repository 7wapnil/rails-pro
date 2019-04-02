module WalletEntry
  class AuthorizationService < ApplicationService
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
        create_default_balance_entry_request! if @request.balance_entry_requests
                                                         .empty?
        update_wallet!
        create_entry!
        update_balances!
        @entry
      end
    end

    def create_entry!
      @entry = Entry.create!(
        wallet_id: @wallet.id,
        origin: @request.origin,
        entry_request: @request,
        kind: @request.kind,
        amount: @amount,
        authorized_at: Time.zone.now
      )
    end

    def update_wallet!
      @wallet = Wallet.find_or_create_by!(
        customer: @request.customer,
        currency: @request.currency
      )
      total_amount = @request.balance_entry_requests.sum(:amount)
      @wallet.update_attributes!(amount: @wallet.amount + total_amount)
    end

    def update_balance!(balance_request)
      balance = Balance.find_or_create_by!(
        wallet_id: @wallet.id,
        kind: balance_request.kind
      )
      result_amount = balance.amount + balance_request.amount
      balance.update_attributes!(amount: result_amount)

      balance_entry = BalanceEntry.create!(
        balance_id: balance.id,
        entry_id: @entry.id,
        amount: balance_request.amount
      )
      balance_request.update_attributes!(balance_entry_id: balance_entry.id)
    end

    def update_balances!
      @request.balance_entry_requests.each do |balance_request|
        update_balance!(balance_request)
      end
    end

    def create_default_balance_entry_request!
      BalanceEntryRequest.create(entry_request: @request,
                                 amount: @amount,
                                 kind: Balance::REAL_MONEY)
    end

    def handle_success
      @request.succeeded!
      log_success

      @entry
    end

    def handle_failure(exception)
      @request.update_columns(
        status: EntryRequest::FAILED,
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
