module Payments
  module Wirecard
    class PaymentRequest
      include Methods

      def initialize(transaction)
        @transaction = transaction
      end

      def build
        {
          'payment': {
            'merchant-account-id': {
              'value': ENV['WIRECARD_MERCHANT_ACCOUNT_ID']
            },
            'request-id': transaction.id,
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
            'success-redirect-url': success_redirect_url,
            'fail-redirect-url': fail_redirect_url,
            'cancel-redirect-url': cancel_redirect_url
          }
        }
      end

      private

      def transaction
        @transaction
      end

      def success_redirect_url
        "#{redirect_domain}/success"
      end

      def fail_redirect_url
        "#{redirect_domain}/fail"
      end

      def cancel_redirect_url
        "#{redirect_domain}/cancel"
      end

      def redirect_domain
        'https://backend.arcanedemo.com/payments/wirecard'
      end
    end
  end
end
