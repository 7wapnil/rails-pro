# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module PaymentDetails
        class RequestBuilder < ApplicationService
          TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'

          delegate :customer, to: :entry_request

          def initialize(entry_request:)
            @entry_request = entry_request
          end

          def call
            payload.merge(checksum: checksum)
          end

          private

          attr_reader :entry_request

          def payload
            @payload ||= {
              merchantId: ENV['SAFECHARGE_MERCHANT_ID'],
              merchantSiteId: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
              userTokenId: user_token_id,
              clientRequestId: timestamp.to_i,
              timeStamp: timestamp.strftime(TIMESTAMP_FORMAT)
            }
          end

          def user_token_id
            entry_request.idebit? ? "000#{customer.id}" : customer.id
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
