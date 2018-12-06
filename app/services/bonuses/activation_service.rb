module Bonuses
  class ActivationService < ApplicationService
    def initialize(wallet, bonus)
      @customer = wallet.customer
      @bonus = bonus
      @wallet = wallet
    end

    def call
      customer.activated_bonus&.destroy
      ActivatedBonus.create(bonus_activation_attributes)
    end

    private

    attr_accessor :customer, :bonus, :wallet

    def excluded_attributes
      %i[created_at deleted_at updated_at id]
    end

    def bonus_activation_attributes
      activation_attrs = {
        original_bonus_id: bonus.id,
        customer_id: customer.id,
        wallet_id: wallet.id,
        activated_at: Time.zone.now
      }
      transmitted_attrs = ActivatedBonus.column_names & Bonus.column_names
      transmitted_attrs.map!(&:to_sym)
      bonus_attrs = bonus.attributes
                         .symbolize_keys
                         .slice(*transmitted_attrs)
                         .except(*excluded_attributes)
      activation_attrs.merge(bonus_attrs)
    end
  end
end
