# frozen_string_literal: true

module Withdrawals
  class PaymentMethodRangeSelector < ApplicationService
    delegate :currency, to: :wallet

    def initialize(customer:, payment_method:)
      @customer = customer
      @payment_method = payment_method
    end

    def call
      {
        min_amount: currency_rule&.max_amount&.abs || 0,
        max_amount: currency_rule&.min_amount&.abs || 0,
        code: currency.code
      }
    end

    private

    attr_reader :customer, :payment_method

    def currency_rule
      currency.withdraw_currency_rule
    end

    def currency
      @currency ||= currency_code ? find_exact_currency : fiat_currency
    end

    def find_exact_currency
      Currency.find_by(code: currency_code) || Currency.primary
    end

    def fiat_currency
      customer&.fiat_wallet&.currency || Currency.primary
    end

    def currency_code
      @currency_code ||= ::Payments::Methods::METHOD_PROVIDERS
                         .dig(payment_method, :currency)
    end
  end
end
