module Heartbeat
  class Service
    ALLOWED_PRODUCTS = [1, 3].freeze

    include Callable

    # rubocop:disable Lint/UnusedMethodArgument
    def call(client:, product:, timestamp:, subscribed:)
      raise NotImplementedError
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
