# frozen_string_literal: true

module Payments
  module Withdrawals
    module Methods
      class BitcoinForm
        include ActiveModel::Model

        BITCOIN_ADDRESS_FORMAT_REGEX = /\A(1|3)[a-zA-Z0-9]{26,34}\z/
        TEST_BITCOIN_ADDRESS_FORMAT_REGEX = /\A(tb1)[a-zA-Z0-9]{26,40}\z/
        WRONG_FORMAT_MESSAGE =
          'payments.withdrawals.payment_methods.bitcoin.errors.address_format'

        attr_accessor :bitcoin_address

        validates :bitcoin_address, presence: true
        validates :bitcoin_address,
                  format: {
                    with: ->(*) { validation_expression },
                    message: I18n.t(WRONG_FORMAT_MESSAGE)
                  }

        class << self
          private

          def validation_expression
            return TEST_BITCOIN_ADDRESS_FORMAT_REGEX if test_mode?

            BITCOIN_ADDRESS_FORMAT_REGEX
          end

          def test_mode?
            ENV.fetch('COINSPAID_MODE', 'test') == 'test'
          end
        end
      end
    end
  end
end
