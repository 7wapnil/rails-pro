module Payments
  module Wirecard
    class PaymentRequest
      include Methods

      attr_reader :transaction

      def initialize(transaction)
        @transaction = transaction
      end

      def build
        {
          'payment': {
            'merchant-account-id': {
              'value': ENV['WIRECARD_MERCHANT_ACCOUNT_ID']
            },
            'request-id': "{{$guid}}:#{transaction.id}",
            'transaction-type': 'authorization',
            'requested-amount': {
              'value': transaction.amount,
              'currency': transaction.currency.code
            },
            'account-holder': {
              'first-name': transaction.customer.first_name,
              'last-name': transaction.customer.last_name
            },
            'payment-methods': {
              'payment-method': [
                { 'name': provider_method_name(transaction.method) }
              ]
            },
            'redirect-url': notification_url,
            'success-redirect-url': notification_url,
            'fail-redirect-url': notification_url,
            'cancel-redirect-url': notification_url
          }
        }
      end

      private

      def notification_url
        "http://localhost:3000/payments/wirecard/notification"
      end
    end
  end
end
