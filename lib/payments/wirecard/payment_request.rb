module Payments
  module Wirecard
    class PaymentRequest
      include Methods

      attr_reader :transaction

      def initialize(transaction)
        @transaction = transaction
      end

      def build # rubocop:disable Metrics/MethodLength
        {
          'payment': {
            'merchant-account-id': {
              'value': ENV['WIRECARD_MERCHANT_ACCOUNT_ID']
            },
            'request-id': "{{$guid}}:#{transaction.id}",
            'transaction-type': 'authorization',
            'requested-amount': request_amount,
            'account-holder': account_holder,
            'payment-methods': payment_method,
            'redirect-url': notification_url,
            'success-redirect-url': notification_url,
            'fail-redirect-url': notification_url,
            'cancel-redirect-url': notification_url
          }
        }
      end

      private

      # TODO: Replace with dynamic domain
      def notification_url
        'http://localhost:3000/payments/wirecard/notification'
      end

      def request_amount
        { 'value': transaction.amount, 'currency': transaction.currency.code }
      end

      def account_holder
        { 'first-name': transaction.customer.first_name,
          'last-name': transaction.customer.last_name }
      end

      def payment_method
        {
          'payment-method': [
            { 'name': provider_method_name(transaction.method) }
          ]
        }
      end
    end
  end
end
