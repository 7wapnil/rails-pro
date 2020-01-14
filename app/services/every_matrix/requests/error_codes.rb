# frozen_string_literal: true

module EveryMatrix
  module Requests
    module ErrorCodes
      SUCCESS_CODE = 0
      SUCCESS_MESSAGE = 'Success'

      UNKNOWN_ERROR_CODE = 101
      UNKNOWN_ERROR_MESSAGE = 'Unknown error'

      USER_NOT_FOUND_CODE = 103
      USER_NOT_FOUND_MESAGE = 'User not found'

      INSUFFICIENT_FUNDS_CODE = 104
      INSUFFICIENT_FUNDS_MESSAGE = 'Insufficient funds'

      MAX_STAKE_LIMIT_EXCEEDED_CODE = 112
      MAX_STAKE_LIMIT_EXCEEDED_MESSAGE = 'MaxStakeLimitExceeded'

      TRANSACTION_NOT_FOUND_CODE = 108
      TRANSACTION_NOT_FOUND_MESSAGE = 'TransactionNotFound'
    end
  end
end
