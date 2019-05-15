# frozen_string_literal: true

module Bonuses
  class ActivationService < ApplicationService
    delegate :customer, to: :wallet, allow_nil: true

    def initialize(wallet:, bonus:, amount:, initiator:)
      @wallet = wallet
      @bonus = bonus
      @amount = amount
      @initiator = initiator
    end

    def call
      log_activation_attempt

      create_customer_bonus!
      charge_bonus_money

      log_successful_activation

      customer_bonus
    end

    private

    attr_accessor :wallet, :bonus, :amount, :initiator, :customer_bonus

    def log_activation_attempt
      initiator.log_event(:bonus_activation, { code: bonus.code }, customer)
    end

    def create_customer_bonus!
      @customer_bonus = CustomerBonuses::Create.call(
        wallet: wallet,
        bonus: bonus,
        amount: amount,
        status: CustomerBonus::ACTIVE
      )
    end

    def charge_bonus_money
      entry_request = EntryRequests::Factories::BonusChange.call(
        customer_bonus: customer_bonus,
        amount: amount,
        initiator: initiator
      )

      EntryRequests::BonusChangeWorker.perform_async(entry_request.id)
    end

    def log_successful_activation
      initiator.log_event(:bonus_activated, customer_bonus, customer)
    end
  end
end
