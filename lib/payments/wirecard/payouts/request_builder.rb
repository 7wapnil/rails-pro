# frozen_string_literal: true

module Payments
  module Wirecard
    module Payouts
      class RequestBuilder < ::Payments::Wirecard::RequestBuilder
        def call
          {
            merchant_account_id: ENV['WIRECARD_MERCHANT_ACCOUNT_ID'],
            request_id: request_id,
            payment_method: 'creditcard',
            requested_amount_currency: transaction.currency.code,
            requested_amount: transaction.amount,
            transaction_type: 'credit',
            token_id: transaction.details['token_id'],
            masked_account_number: transaction.details['masked_account_number'],
            notification_url: webhook_url
          }
        end
      end
    end
  end
end
