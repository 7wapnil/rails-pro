# frozen_string_literal: true

module Payments
  module Wirecard
    module Statuses
      CANCELLED_BY_MERCHANT = '500.1107'
      CANCELLED = '500.1108'

      CANCELLED_STATUSES = [CANCELLED_BY_MERCHANT, CANCELLED].freeze
      APPROVED_STATUSES_REGEX = /(200\.\d+|201.0000)/
    end
  end
end
