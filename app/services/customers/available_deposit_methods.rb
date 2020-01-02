# frozen_string_literal: true

module Customers
  class AvailableDepositMethods < ApplicationService
    def initialize(customer:)
      @customer = customer
    end

    def call
      [*fiat_deposit_methods.compact, *crypto_deposit_methods.compact]
    end

    private

    attr_reader :customer

    def fiat_deposit_methods
      ::Payments::Fiat::Deposit::PAYMENT_METHODS.map do |payment_method|
        next unless allowed?(payment_method, fiat_currency)

        OpenStruct.new(
          name: payment_method,
          max_amount: max_amount(fiat_currency),
          min_amount: min_amount(fiat_currency)
        )
      end
    end

    def crypto_deposit_methods
      ::Payments::Crypto::Deposit::PAYMENT_METHODS.map do |payment_method|
        currency = crypto_currency(payment_method)
        next unless currency && allowed?(payment_method, currency)

        OpenStruct.new(
          name: payment_method,
          max_amount: max_amount(currency),
          min_amount: min_amount(currency)
        )
      end
    end

    def allowed?(payment_method, currency)
      ::Payments::Validation.call(transaction(payment_method, currency))
    end

    def crypto_currency(payment_method)
      code = currency_code(payment_method)
      crypto_currencies.find { |currency| currency.code == code }
    end

    def fiat_currency
      @fiat_currency ||= customer.currencies
                                 .fiat
                                 .includes(:deposit_currency_rule)
                                 .first
    end

    def max_amount(currency)
      currency.deposit_currency_rule&.max_amount
    end

    def min_amount(currency)
      currency.deposit_currency_rule&.min_amount
    end

    def transaction(mode, currency)
      ::Payments::Transactions::Validation.new(
        method: mode,
        customer: customer,
        currency: currency
      )
    end

    def crypto_currencies
      @crypto_currencies ||= Currency.crypto
                                     .includes(:deposit_currency_rule)
                                     .load
    end

    def currency_code(payment_method)
      ::Payments::Methods::METHOD_PROVIDERS.dig(payment_method, :currency)
    end
  end
end
