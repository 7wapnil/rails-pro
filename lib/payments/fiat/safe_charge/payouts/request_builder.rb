# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Payouts
        class RequestBuilder < ApplicationService
          include ::Payments::Methods

          TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'

          delegate :customer, :currency, :amount, to: :transaction
          delegate :code, to: :currency, allow_nil: true, prefix: true

          def initialize(transaction:)
            @transaction = transaction
          end

          def call
            {
              **general_params,
              checksum: checksum
            }
          end

          private

          attr_reader :transaction

          def general_params
            {
              merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
              merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
              userTokenId: customer.id,
              userPMId: transaction.details['user_payment_option_id'],
              amount: transaction.amount.abs,
              currency: currency_code,
              merchantWDRequestId: transaction.id,
              merchantUniqueId: transaction.id,
              timeStamp: timestamp
            }
          end

          def payment_option
            { userPaymentOptionId:
                transaction.details['user_payment_option_id'] }
          end

          def comment
            "Withdraw #{transaction.amount} from your #{currency_code} wallet" \
            " on #{ENV['BRAND_NAME']}"
          end

          def url_details
            { notificationUrl: webhook_url }
          end

          def timestamp
            @timestamp ||= Time.zone.now.strftime(TIMESTAMP_FORMAT)
          end

          def checksum
            Digest::SHA256.hexdigest(checksum_string)
          end

          def checksum_string
            [
              *general_params.values,
              ENV['SAFECHARGE_SECRET_KEY']
            ].map(&:to_s).join
          end

          def web_protocol
            @web_protocol ||= ENV.fetch('WEB_PROTOCOL', DEFAULT_WEB_PROTOCOL)
          end
        end
      end
    end
  end
end
