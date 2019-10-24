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
      @customer_bonus.activate!(customer_bonus.entry)
      log_successful_activation

      customer_bonus
    end

    private

    attr_accessor :wallet, :bonus, :amount, :initiator,
                  :customer_bonus, :entry_request

    def log_activation_attempt
      initiator.log_event(:bonus_activation, { code: bonus.code }, customer)
    end

    def create_customer_bonus!
      @customer_bonus = CustomerBonuses::Create.call(
        wallet: wallet,
        bonus: bonus,
        amount: amount
      )
    end

    def charge_bonus_money
      create_entry_request!

      return charge_failed! if entry_request.failed?

      EntryRequests::BonusChangeService.call(entry_request: entry_request)
    end

    def create_entry_request!
      @entry_request = EntryRequests::Factories::BonusChange.call(
        customer_bonus: customer_bonus,
        amount: amount,
        initiator: initiator
      )
    end

    def charge_failed!
      raise CustomerBonuses::ActivationError, entry_request.result['message']
    end

    def log_successful_activation
      initiator.log_event(:bonus_activated, customer_bonus, customer)
    end
  end
end
