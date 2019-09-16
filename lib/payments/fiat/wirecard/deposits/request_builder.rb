# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      module Deposits
        class RequestBuilder < ::Payments::Fiat::Wirecard::RequestBuilder
          def call
            {
              'payment': {
                'merchant-account-id': {
                  'value': ENV['WIRECARD_MERCHANT_ACCOUNT_ID']
                },
                'request-id': request_id,
                'transaction-type': 'purchase',
                'requested-amount': request_amount,
                'account-holder': account_holder,
                'payment-methods': payment_method,
                'redirect-url': webhook_url
              }
            }
          end

          private

          def request_id
            "#{transaction.id}:#{Time.zone.now}"
          end

          def request_amount
            {
              'value': transaction.amount,
              'currency': transaction.currency.code
            }
          end

          def account_holder
            { 'first-name': transaction.customer.first_name,
              'last-name': transaction.customer.last_name }
          end
        end
      end
    end
  end
end
