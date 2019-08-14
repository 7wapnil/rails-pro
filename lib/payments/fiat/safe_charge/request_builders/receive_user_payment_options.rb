# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module RequestBuilders
        class ReceiveUserPaymentOptions < ApplicationService
          TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'

          def initialize(customer:)
            @customer = customer
          end

          def call
            payload.merge(checksum: checksum)
          end

          private

          attr_reader :customer

          def payload
            @payload ||= {
              merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
              merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
              userTokenId: customer.id,
              clientRequestId: timestamp.to_i,
              timeStamp: timestamp.strftime(TIMESTAMP_FORMAT)
            }
          end

          def checksum
            Digest::SHA256.hexdigest(checksum_string)
          end

          def checksum_string
            [
              payload[:merchantId],
              payload[:merchantSiteId],
              payload[:userTokenId],
              payload[:clientRequestId],
              payload[:timeStamp],
              ENV['SAFECHARGE_SECRET_KEY']
            ].map(&:to_s).join
          end

          def timestamp
            @timestamp ||= Time.zone.now
          end
        end
      end
    end
  end
end
