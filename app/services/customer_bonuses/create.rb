# frozen_string_literal: true

module CustomerBonuses
  class Create < ApplicationService
    delegate :customer, to: :wallet, allow_nil: true
    delegate :currency, to: :wallet, allow_nil: true

    def initialize(wallet:, bonus:, amount:, **params)
      @wallet = wallet
      @bonus = bonus
      @amount = amount.to_f
      @status = params.fetch(:status, CustomerBonus::INITIAL)
      @activated_at = params[:activated_at]
    end

    def call
      check_bonus_expiration!
      form = CustomerBonuses::CreateForm.new(
        amount: amount,
        currency: currency,
        **new_bonus_attributes
      )
      form.submit!

      form.subject
    end

    private

    attr_accessor :wallet, :bonus, :amount, :status, :activated_at

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def new_bonus_attributes
      {
        original_bonus_id: bonus.id,
        customer_id: customer.id,
        wallet_id: wallet.id,
        rollover_balance: rollover_value,
        rollover_initial_value: rollover_value,
        code: bonus.code,
        kind: bonus.kind,
        rollover_multiplier: bonus.rollover_multiplier,
        max_rollover_per_bet: max_rollover_per_bet,
        max_deposit_match: max_deposit_match,
        min_odds_per_bet: bonus.min_odds_per_bet,
        min_deposit: min_deposit,
        valid_for_days: bonus.valid_for_days,
        percentage: bonus.percentage,
        expires_at: bonus.expires_at,
        status: new_customer_bonus_status,
        activated_at: activated_at
      }
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def new_customer_bonus_status
      return CustomerBonus::EXPIRED unless bonus.active?

      @status
    end

    def rollover_value
      @rollover_value ||= bonus_amount * bonus.rollover_multiplier
    end

    def bonus_amount
      BalanceCalculations::Deposit.call(amount, currency, bonus)[:bonus_amount]
    end

    def check_bonus_expiration!
      return true unless customer&.active_bonus&.time_exceeded?

      CustomerBonuses::Deactivate.call(
        bonus: customer.active_bonus,
        action: CustomerBonuses::Deactivate::EXPIRE
      )
    end

    def convert_to_wallet_currency(amount)
      Exchanger::Converter.call(
        amount,
        Currency.primary,
        wallet.currency
      )
    end

    def max_rollover_per_bet
      @max_rollover_per_bet ||=
        convert_to_wallet_currency(bonus.max_rollover_per_bet)
    end

    def max_deposit_match
      @max_deposit_match ||=
        convert_to_wallet_currency(bonus.max_deposit_match)
    end

    def min_deposit
      @min_deposit ||=
        convert_to_wallet_currency(bonus.min_deposit)
    end
  end
end
