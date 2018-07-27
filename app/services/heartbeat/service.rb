module Heartbeat
  class Service
    ALLOWED_PRODUCTS = [1, 3]

    include Callable

    def call(client:, product:, timestamp:, subscribed:)
      raise NotImplementedError
    end
  end
end
