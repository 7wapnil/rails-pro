# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Validations
        class CustomerValidationHandler < ApplicationService
          include ::Payments::Methods

          delegate :customer, to: :transaction
          delegate :address, to: :customer
          delegate :state_code, :country_code, to: :address, allow_nil: true

          def initialize(transaction)
            @transaction = transaction
          end

          def call
            supported_currency? && supported_country? && supported_state?
          end

          private

          attr_reader :transaction

          def supported_currency?
            return true unless transaction.currency

            ::Payments::Fiat::SafeCharge::Currency::AVAILABLE_CURRENCY_LIST
              .fetch(mode, [])
              .include?(transaction.currency.code)
          end

          def supported_country?
            return true unless country_code

            ::Payments::Fiat::SafeCharge::Country::AVAILABLE_COUNTRIES
              .fetch(mode, [])
              .include?(country_code)
          end

          def supported_state?
            return true unless available_states.key?(country_code)

            available_states[country_code].include?(state_code)
          end

          def available_states
            ::Payments::Fiat::SafeCharge::State::AVAILABLE_STATES
          end

          def mode
            @mode ||= provider_method_name(transaction.method)
          end
        end
      end
    end
  end
end
