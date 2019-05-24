# frozen_string_literal: true

module Bets
  module Notification
    EXCEPTION_CODES = [
      INTERNAL_SERVER_ERROR = 'internal_server_error',
      PLACEMENT_ERROR = 'placement_error',
      INTERNAL_VALIDATION_ERROR = 'internal_validation_error',
      EXTERNAL_VALIDATION_ERROR = 'external_validation_error',
      MTS_CANCELLATION_ERROR = 'mts_cancellation_error'
    ].freeze

    DEFAULT_EXCEPTION_CODE = INTERNAL_SERVER_ERROR

    CODES = [*EXCEPTION_CODES].freeze
  end
end
