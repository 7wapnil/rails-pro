# frozen_string_literal: true

module Currencies
  class Update < ApplicationService
    def initialize(params:, current_user:)
      @params = params
      @current_user = current_user
    end

    def call
      validate_deposit_currency_rule! if currency.crypto?

      log_event if currency.errors.empty? && currency.update(params)

      currency
    end

    private

    attr_reader :params, :current_user

    def validate_deposit_currency_rule!
      ::EntryCurrencyRules::Crypto::DepositRuleForm.new(
        currency: currency,
        params: deposit_currency_rule_params
      ).validate!
    end

    def currency
      @currency ||= Currency.find(params[:id])
    end

    def deposit_currency_rule_params
      params[:entry_currency_rules_attributes]
        .to_h
        .values
        .find { |rule| rule['kind'] == EntryKinds::DEPOSIT }
    end

    def log_event
      current_user.log_event :currency_updated, currency
    end
  end
end
