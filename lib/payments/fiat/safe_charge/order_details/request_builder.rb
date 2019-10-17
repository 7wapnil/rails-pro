# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module OrderDetails
        class RequestBuilder < ApplicationService
          TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'

          def initialize(transaction:, order_id:)
            @transaction = transaction
            @order_id = order_id
          end

          def call
            {
              **general_params,
              checksum: checksum
            }
          end

          private

          attr_reader :transaction, :order_id

          def general_params
            {
              merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
              merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
              wdOrderId: order_id,
              merchantUniqueId: transaction.id,
              timeStamp: timestamp
            }
          end

          def checksum
            Digest::SHA256.hexdigest(checksum_string)
          end

          def timestamp
            @timestamp ||= Time.zone.now.strftime(TIMESTAMP_FORMAT)
          end

          def checksum_string
            [
              *general_params.values,
              ENV['SAFECHARGE_SECRET_KEY']
            ].map(&:to_s).join
          end
        end
      end
    end
  end
end
