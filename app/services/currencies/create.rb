# frozen_string_literal: true

module Currencies
  class Create < ApplicationService
    def initialize(params:, current_user:)
      @params = params
      @current_user = current_user
    end

    def call
      validate_currency_rules! if currency.crypto?

      log_event if currency.errors.empty? && currency.save

      currency
    end

    private

    attr_reader :params, :current_user

    def validate_currency_rules!
      Currencies::CurrencyRules::CryptoLimitValidator
        .call(currency: currency, params: currency_rule_params)
    end

    def currency
      @currency ||= Currency.new(params)
    end

    def currency_rule_params
      params[:entry_currency_rules_attributes]
        .to_h
        .values
        .find { |rule| rule['kind'] == EntryKinds::DEPOSIT }
    end

    def log_event
      current_user.log_event :currency_created, currency
    end
  end
end
