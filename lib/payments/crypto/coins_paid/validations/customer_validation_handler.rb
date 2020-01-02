# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      module Validations
        class CustomerValidationHandler < ApplicationService
          include ::Payments::Methods

          delegate :currency, to: :transaction, allow_nil: true

          def initialize(transaction)
            @transaction = transaction
          end

          def call
            return true unless currency

            currency.code == ::Payments::Crypto::CoinsPaid::Currency::MBTC_CODE
          end

          private

          attr_reader :transaction
        end
      end
    end
  end
end
