# frozen_string_literal: true

module WalletEntry
  class UpdateBalances < ApplicationService
    delegate :entry_request, :wallet, :origin, to: :entry

    def initialize(entry:)
      @entry = entry
    end

    def call
      lock_customer_bonus!
      update_balance!
      update_customer_bonus!
      update_entry!
    end

    private

    attr_reader :entry, :customer_bonus

    def lock_customer_bonus!
      @customer_bonus = assigned_customer_bonus&.lock!
    end

    def update_balance!
      ::Forms::AmountChange.new(wallet, request: entry_request).save!
    end

    def update_customer_bonus!
      return unless customer_bonus.present?

      customer_bonus.update!(
        total_converted_amount: total_converted_amount,
        total_confiscated_amount: total_confiscated_amount
      )
    end

    def update_entry!
      entry.update!(balance_attributes)
    end

    def balance_attributes
      {
        real_money_amount: entry_request.real_money_amount,
        base_currency_real_money_amount: base_currency_real_money_amount,
        bonus_amount: entry_request.bonus_amount,
        base_currency_bonus_amount: base_currency_bonus_amount,
        balance_amount_after: current_balance_amount,
        bonus_amount_after: wallet.bonus_balance,
        **bonus_track_attributes.compact
      }
    end

    def bonus_track_attributes
      return {} unless customer_bonus.present?

      {
        converted_bonus_amount: entry_request.converted_bonus_amount,
        converted_bonus_amount_after: total_converted_amount,
        base_currency_converted_bonus_amount: base_currency_converted_amount,
        confiscated_bonus_amount: entry_request.confiscated_bonus_amount,
        confiscated_bonus_amount_after: total_confiscated_amount,
        base_currency_confiscated_bonus_amount: base_currency_confiscated_amount
      }
    end

    def base_currency_real_money_amount
      base_currency_amount(entry_request.real_money_amount)
    end

    def base_currency_bonus_amount
      base_currency_amount(entry_request.bonus_amount)
    end

    def base_currency_converted_amount
      base_currency_amount(entry_request.converted_bonus_amount)
    end

    def base_currency_confiscated_amount
      base_currency_amount(entry_request.confiscated_bonus_amount)
    end

    def total_converted_amount
      @total_converted_amount ||= customer_bonus.total_converted_amount +
                                  entry_request.converted_bonus_amount
    end

    def total_confiscated_amount
      @total_confiscated_amount ||= customer_bonus.total_confiscated_amount +
                                    entry_request.confiscated_bonus_amount
    end

    def current_balance_amount
      wallet.real_money_balance + wallet.bonus_balance
    end

    def assigned_customer_bonus
      return origin if origin.is_a?(CustomerBonus)
      return unless origin.respond_to?(:customer_bonus)

      origin.customer_bonus
    end

    def base_currency_amount(amount)
      Exchanger::Converter.call(amount, wallet.currency, primary_currency)
    end

    def primary_currency
      @primary_currency ||= Currency.primary
    end
  end
end
