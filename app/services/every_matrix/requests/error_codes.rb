# frozen_string_literal: true

module EveryMatrix
  module Requests
    module ErrorCodes
      SUCCESS_CODE = 0
      SUCCESS_MESSAGE = 'Success'

      USER_NOT_FOUND_CODE = 103
      USER_NOT_FOUND_MESAGE = 'User not found'

      INSUFFICIENT_FUNDS_CODE = 104
      INSUFFICIENT_FUNDS_MESSAGE = 'Insufficient funds'

      MAX_STAKE_LIMIT_EXCEEDED_CODE = 112
      MAX_STAKE_LIMIT_EXCEEDED_MESSAGE = 'MaxStakeLimitExceeded'
    end
  end
end
