# frozen_string_literal: true

module EveryMatrix
  class Connection < ::ApplicationState
    enum status: {
      dead: DEAD = 'dead',
      recovering: RECOVERING = 'recovering',
      healthy: HEALTHY = 'healthy'
    }
  end
end
