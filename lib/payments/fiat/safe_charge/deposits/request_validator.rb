# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Deposits
        class RequestValidator < ApplicationService
          include ::Payments::Methods

          MANDATORY_FIELDS = %i[
            merchantId merchantSiteId timeStamp currency
            userTokenId amount checksum paymentMethod
          ].freeze

          def initialize(deposit_params)
            @deposit_params = deposit_params
          end

          def call
            check_mandatory_fields!
            check_currency!
            check_country!
            check_state!
          end

          private

          attr_reader :deposit_params

          def check_mandatory_fields!
            return unless missing_mandatory_fields.any?

            raise_validation_error(
              "Fields are required: #{missing_mandatory_fields.join(', ')}"
            )
          end

          def check_currency!
            return if currency_available?

            raise_validation_error(
              I18n.t('errors.messages.currency_not_supported')
            )
          end

          def check_country!
            return if valid_country?

            raise_validation_error(
              I18n.t('errors.messages.country_not_supported')
            )
          end

          def check_state!
            return if valid_state?

            raise_validation_error(
              I18n.t('errors.messages.state_not_supported')
            )
          end

          def missing_mandatory_fields
            @missing_mandatory_fields ||= MANDATORY_FIELDS - fields_with_value
          end

          def raise_validation_error(message)
            raise ::SafeCharge::InvalidParameterError, message
          end

          def fields_with_value
            deposit_params.reject { |_k, value| value.blank? }.keys
          end

          def currency_available?
            ::Payments::Fiat::SafeCharge::Currency::AVAILABLE_CURRENCY_LIST
              .fetch(deposit_params[:paymentMethod], [])
              .include?(deposit_params[:currency])
          end

          def valid_country?
            return true unless address[:country]

            ::Payments::Fiat::SafeCharge::Country::AVAILABLE_COUNTRIES
              .fetch(deposit_params[:paymentMethod], [])
              .include?(address[:country])
          end

          def valid_state?
            return true unless address[:country]
            return true unless address[:state]
            return true unless available_states[address[:country]]

            available_state?
          end

          def address
            deposit_params[:billingAddress]
          end

          def available_state?
            available_states[address[:country]].include?(address[:state])
          end

          def available_states
            ::Payments::Fiat::SafeCharge::State::AVAILABLE_STATES
          end
        end
      end
    end
  end
end
