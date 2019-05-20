# frozen_string_literal: true

module WalletEntry
  class AuthorizationService < ApplicationService
    def initialize(request)
      @request = request
      @amount = request.amount
    end

    def call
      request.validate!
      update_database!
      handle_success
    rescue ActiveRecord::RecordInvalid, ActiveModel::ValidationError => e
      handle_failure e
    end

    private

    attr_reader :request, :amount, :wallet, :entry

    def update_database!
      ActiveRecord::Base.transaction do
        create_default_balance_entry_request! if no_balance_entry_requests?
        update_wallet!
        create_entry!
        update_balances!

        entry
      end
    end

    def no_balance_entry_requests?
      request.balance_entry_requests.empty?
    end

    def create_default_balance_entry_request!
      BalanceEntryRequest.create(
        entry_request: request,
        amount: amount,
        kind: Balance::REAL_MONEY
      )
    end

    def update_wallet!
      @wallet = Wallet.find_or_create_by!(
        customer: request.customer,
        currency: request.currency
      )
      amount_increment = request.balance_entry_requests.sum(:amount)
      ::Forms::AmountChange
        .new(wallet, amount_increment: amount_increment, request: request)
        .save!
    end

    def create_entry!
      @entry = Entry.create!(
        wallet_id: wallet.id,
        origin_type: request.origin_type,
        origin_id: request.origin_id,
        entry_request: request,
        kind: request.kind,
        amount: amount,
        authorized_at: Time.zone.now
      )
    end

    def update_balances!
      UpdateBalances.call(entry: entry)
    end

    def handle_success
      request.succeeded!
      log_success

      entry
    end

    def handle_failure(exception)
      request.update_columns(
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
        user: initiator,
        customer: request.customer,
        context: request
      )
    end

    def initiator
      return if request.customer_initiated?

      request.initiator
    end

    def log_failure
      Audit::Service.call(
        event: :entry_creation_failed,
        user: initiator,
        customer: request.customer,
        context: request
      )
    end
  end
end
