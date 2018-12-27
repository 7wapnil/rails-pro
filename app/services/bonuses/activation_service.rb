module Bonuses
  class ActivationService < ApplicationService
    def initialize(wallet, bonus, amount = nil)
      @customer = wallet.customer
      @bonus = bonus
      @wallet = wallet
      @amount = amount
    end

    def call
      if customer.customer_bonus
        CustomerBonuses::ExpirationService.call(
          customer.customer_bonus,
          :expired_by_new_activation
        )
      end
      CustomerBonus.create!(bonus_activation_attributes)
    end

    private

    attr_accessor :customer, :bonus, :wallet, :amount

    def excluded_attributes
      %i[created_at deleted_at updated_at id]
    end

    def rollover_value
      @rollover_value ||= begin
        raise NotImplementedError unless amount

        bonus_amount = BalanceCalculations::Deposit.call(bonus, amount)[:bonus]
        bonus_amount * bonus.rollover_multiplier
      end
    end

    def bonus_activation_attributes # rubocop:disable Metrics/MethodLength
      activation_attrs = {
        original_bonus_id: bonus.id,
        customer_id: customer.id,
        wallet_id: wallet.id,
        rollover_balance: rollover_value,
        rollover_initial_value: rollover_value
      }
      transmitted_attrs = CustomerBonus.column_names & Bonus.column_names
      transmitted_attrs.map!(&:to_sym)
      bonus_attrs = bonus.attributes
                         .symbolize_keys
                         .slice(*transmitted_attrs)
                         .except(*excluded_attributes)
      activation_attrs.merge(bonus_attrs)
    end
  end
end
