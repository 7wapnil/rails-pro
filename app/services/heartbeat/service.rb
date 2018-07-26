module Heartbeat
  class Service
    include Callable

    def call(client:, product:, timestamp:, subscribed:)
      raise NotImplementedError
    end
  end
end
