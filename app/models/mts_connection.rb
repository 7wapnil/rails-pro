# frozen_string_literal: true

class MtsConnection < ApplicationState
  enum status: {
    recovering: RECOVERING = 'recovering',
    healthy:    HEALTHY    = 'healthy'
  }
end
