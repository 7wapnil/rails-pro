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
      log_success

      entry
    rescue ActiveRecord::RecordInvalid, ActiveModel::ValidationError => e
      handle_failure e
    end

    private

    attr_reader :request, :amount, :wallet, :entry

    def update_database!
      ActiveRecord::Base.transaction do
        find_or_create_wallet_with_lock!
        create_entry!
        update_balances!
        confirm_entry if auto_confirmation?
        request.succeeded!
      end
    end

    def no_balance_updates?
      request.real_money_amount.zero? && request.bonus_amount.zero?
    end

    def perform_default_balance_update!
      request.update(real_money_amount: amount)
    end

    def find_or_create_wallet_with_lock!
      @wallet = Wallets::FindOrCreate.call(
        customer: request.customer,
        currency: request.currency
      ).lock!
    end

    def create_entry!
      base_currency_amount = Exchanger::Converter
                             .call(amount, request.currency.code)
      @entry = Entry.create!(
        wallet_id: wallet.id,
        origin_type: request.origin_type,
        origin_id: request.origin_id,
        entry_request: request,
        kind: request.kind,
        amount: amount,
        base_currency_amount: base_currency_amount,
        authorized_at: Time.zone.now
      )
    end

    def update_balances!
      UpdateBalances.call(entry: entry)
    end

    def auto_confirmation?
      EntryKinds::DELAYED_CONFIRMATION_KINDS.exclude?(entry.kind)
    end

    def confirm_entry
      entry.update(confirmed_at: Time.zone.now)
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
