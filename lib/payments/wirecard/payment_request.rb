module Payments
  module Wirecard
    class PaymentRequest
      include ::Payments::Methods
      include Rails.application.routes.url_helpers

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
            'requested-amount': request_amount,
            'account-holder': account_holder,
            'payment-methods': payment_method,
            'redirect-url': webhook_url
          }
        }
      end

      private

      def webhook_url
        webhooks_wirecard_payment_url(
          host: ENV['APP_HOST'],
          protocol: :https,
          request_id: transaction.id
        )
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
