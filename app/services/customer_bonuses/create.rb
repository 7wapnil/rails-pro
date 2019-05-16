# frozen_string_literal: true

module CustomerBonuses
  class Create < ApplicationService
    delegate :customer, to: :wallet, allow_nil: true

    def initialize(wallet:, original_bonus:, **params)
      @wallet = wallet
      @bonus = original_bonus
      @amount = params[:amount].to_f
      @update_wallet = params.fetch(:update_wallet, false)
      @initiator = params[:user]
    end

    def call
      check_bonus_expiration!
      log_activation_attempt if initiator
      create_customer_bonus!
      add_bonus_money if update_wallet?
      log_successful_activation if initiator

      customer_bonus
    end

    private

    attr_accessor :wallet, :bonus, :amount, :update_wallet, :initiator

    def log_activation_attempt
      initiator.log_event(:bonus_activation, customer_bonus, customer)
    end

    def create_customer_bonus!
      CustomerBonuses::CreateForm.new(subject: customer_bonus).submit!
    end

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
        expires_at: bonus.expires_at
      }
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def rollover_value
      @rollover_value ||= bonus_amount * bonus.rollover_multiplier
    end

    def bonus_amount
      BalanceCalculations::Deposit.call(bonus, amount)[:bonus]
    end

    def add_bonus_money
      request = EntryRequests::Factories::BonusChange
                .call(wallet: wallet, amount: amount, initiator: initiator)

      EntryRequests::BonusChangeWorker.perform_async(request.id)
    end

    def update_wallet?
      update_wallet.present?
    end

    def log_successful_activation
      initiator.log_event(:bonus_activated, customer_bonus, customer)
    end

    def check_bonus_expiration!
      return true unless customer.active_bonus&.expired?

      CustomerBonuses::Deactivate.call(bonus: customer_bonus, action: :expire!)
      failure_message = I18n.t('errors.messages.bonus_expired')
      entry_request.register_failure!(failure_message)
    end
  end
end
