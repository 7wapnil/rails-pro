# frozen_string_literal: true

module EntryCurrencyRules
  module Crypto
    class DepositRuleValidation < ApplicationService
      include Payments::Crypto::SuppliedCurrencies

      def initialize(params:, currency:)
        @params = params
        @currency = currency
      end

      def call
        return unless form_class

        form_class.new(params: params, currency: currency).validate
      end

      private

      attr_reader :params, :currency

      def form_class
        @form_class ||= case currency.code
                        when M_TBTC, M_BTC then coins_paid_form
                        end
      end

      def coins_paid_form
        ::EntryCurrencyRules::Crypto::DepositRules::CoinsPaidForm
      end
    end
  end
end
