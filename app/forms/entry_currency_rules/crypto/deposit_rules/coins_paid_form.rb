# frozen_string_literal: true

module EntryCurrencyRules
  module Crypto
    module DepositRules
      class CoinsPaidForm < BaseForm
        def validate
          return unless external_response.present?
          return if new_min_limit_valid?

          currency.errors.add(:base, I18n.t('errors.messages.limits_error'))
          currency
            .entry_currency_rules
            .find(&:deposit?)
            .errors
            .add(:min_amount, limit_error)
        rescue HTTParty::Error
          currency.errors.add(
            :base,
            I18n.t('errors.messages.crypto_limits_service_unavailable')
          )
        end

        private

        def new_min_limit_valid?
          params['min_amount'].to_f > min_deposit_limit
        end

        def min_deposit_limit
          @min_deposit_limit ||=
            multiply_amount(external_response.dig('minimum_amount').to_f)
        end

        def external_response
          @external_response ||= Payments::Crypto::CoinsPaid::Client
                                 .new
                                 .fetch_limits
                                 .find(&method(:condition))
        end

        def limit_error
          I18n.t('errors.messages.crypto_deposit_limit',
                 limit: min_deposit_limit)
        end

        def condition(object)
          object['currency'] == CURRENCY_CONVERTING_MAP[currency.code]
        end
      end
    end
  end
end
