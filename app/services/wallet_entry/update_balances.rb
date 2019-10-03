# frozen_string_literal: true

module WalletEntry
  class UpdateBalances < ApplicationService
    delegate :entry_request, :wallet, to: :entry

    def initialize(entry:)
      @entry = entry
    end

    def call
      update_balance!
      update_entry!
    end

    private

    attr_reader :entry

    def update_balance!
      ::Forms::AmountChange.new(wallet, request: entry_request).save!
    end

    def update_entry!
      entry.update!(
        real_money_amount: entry_request.real_money_amount,
        base_currency_real_money_amount: base_currency_real_money_amount,
        bonus_amount: entry_request.bonus_amount,
        base_currency_bonus_amount: base_currency_bonus_amount,
        balance_amount_after: current_balance_amount,
        bonus_amount_after: wallet.bonus_balance
      )
    end

    def base_currency_real_money_amount
      Exchanger::Converter.call(
        entry_request.real_money_amount,
        wallet.currency.code
      )
    end

    def base_currency_bonus_amount
      Exchanger::Converter.call(
        entry_request.bonus_amount,
        wallet.currency.code
      )
    end

    def current_balance_amount
      wallet.real_money_balance + wallet.bonus_balance
    end
  end
end
