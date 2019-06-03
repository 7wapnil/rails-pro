# frozen_string_literal: true

module CustomerBonuses
  class Create < ApplicationService
    delegate :customer, to: :wallet, allow_nil: true

    def initialize(wallet:, bonus:, amount:, **params)
      @wallet = wallet
      @bonus = bonus
      @amount = amount.to_f
      @status = params.fetch(:status, CustomerBonus::INITIAL)
    end

    def call
      check_bonus_expiration!
      CustomerBonuses::CreateForm.new(subject: customer_bonus).submit!

      customer_bonus
    end

    private

    attr_accessor :wallet, :bonus, :amount, :status

    def customer_bonus
      @customer_bonus ||= CustomerBonus.new(new_bonus_attributes)
    end

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
        max_rollover_per_bet: bonus.max_rollover_per_bet,
        max_deposit_match: bonus.max_deposit_match,
        min_odds_per_bet: bonus.min_odds_per_bet,
        min_deposit: bonus.min_deposit,
        valid_for_days: bonus.valid_for_days,
        percentage: bonus.percentage,
        expires_at: bonus.expires_at,
        status: new_customer_bonus_status
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
      BalanceCalculations::Deposit.call(amount, bonus)[:bonus]
    end

    def check_bonus_expiration!
      return true unless active_bonus_expired?

      CustomerBonuses::Deactivate.call(
        bonus: customer.active_bonus,
        action: CustomerBonuses::Deactivate::EXPIRE
      )
    end

    def active_bonus_expired?
      return false unless customer.active_bonus

      created_at = customer.active_bonus.created_at
      expires_at = created_at + customer.active_bonus.valid_for_days.days

      expires_at < Time.zone.now
    end
  end
end
