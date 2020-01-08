# frozen_string_literal: true

module Payments
  module Fiat
    module Wirecard
      module Statuses
        PROVIDER_SYSTEM_ERROR = '500.1050'
        CANCELLED_UNKNOWN_RESPONSE = '500.1999'
        CANCELLED_BY_MERCHANT = '500.1107'
        CANCELLED = '500.1108'
        CONFIRMED = 201

        DECLINED_STATUSES = [
          PROVIDER_SYSTEM_ERROR,
          CANCELLED_UNKNOWN_RESPONSE
        ].freeze
        CANCELLED_STATUSES = [
          CANCELLED_UNKNOWN_RESPONSE,
          CANCELLED_BY_MERCHANT,
          CANCELLED
        ].freeze
        APPROVED_STATUSES_REGEX = /(200\.\d+|201.0000)/
      end
    end
  end
end
