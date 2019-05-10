# frozen_string_literal: true

module WalletEntry
  class UpdateBalances < ApplicationService
    delegate :entry_request, :wallet, to: :entry

    def initialize(entry:)
      @entry = entry
    end

    def call
      create_missing_balances!
      lock_balances!
      process_balance_requests!
      save_current_balance_amount!
    end

    private

    attr_reader :entry, :balances

    def create_missing_balances!
      entry_request
        .balance_entry_requests
        .map(&:kind)
        .each { |kind| wallet.balances.find_or_create_by!(kind: kind) }
    end

    def lock_balances!
      @balances = wallet.balances.lock(true)
    end

    def process_balance_requests!
      entry_request
        .balance_entry_requests
        .each(&method(:process_balance_request!))
    end

    def process_balance_request!(balance_request)
      balance = balances.find { |item| item.kind == balance_request.kind }

      update_balance!(balance, balance_request)
      create_balance_entry!(balance, balance_request)
    end

    def update_balance!(balance, balance_request)
      ::Forms::AmountChange.new(
        balance,
        amount_increment: balance_request.amount,
        request: entry_request
      ).save!
    end

    def create_balance_entry!(balance, balance_request)
      balance_entry = BalanceEntry.create!(
        balance_id: balance.id,
        entry_id: entry.id,
        amount: balance_request.amount,
        balance_amount_after: balance.amount
      )
      balance_request.update_attributes!(balance_entry_id: balance_entry.id)
    end

    def save_current_balance_amount!
      current_balance_amount = balances.sum(&:amount)

      entry.update_attributes!(balance_amount_after: current_balance_amount)
    end
  end
end
